import { useState, useRef, useCallback, useEffect } from 'react'
import './App.css'

const LEVELS = [
  { level: 1, range: '1–10' },
  { level: 2, range: '11–20' },
  { level: 3, range: '24–70' },
  { level: 4, range: '75-100' },
]

const DEFAULT_API = 'http://localhost:8000'

interface PredictionResult {
  prediction: number
  confidence: number | null
  success: boolean
  message: string
}

interface HealthResult {
  status: string
  loaded_levels?: number[]
  total_levels?: number
  error?: string
}

export default function App() {
  const [level, setLevel] = useState(1)
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<PredictionResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [apiBase, setApiBase] = useState(DEFAULT_API)
  const [health, setHealth] = useState<HealthResult | null>(null)

  // Camera state
  const [cameraReady, setCameraReady] = useState(false)
  const [recording, setRecording] = useState(false)
  const [recordedBlob, setRecordedBlob] = useState<Blob | null>(null)
  const [recordedUrl, setRecordedUrl] = useState<string | null>(null)
  const [recordingTime, setRecordingTime] = useState(0)

  const videoRef = useRef<HTMLVideoElement>(null)
  const playbackRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // Health check
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const res = await fetch(`${apiBase}/api/hearing-impairment/health`)
        const data: HealthResult = await res.json()
        setHealth(data)
      } catch {
        setHealth({ status: 'unreachable' })
      }
    }
    checkHealth()
  }, [apiBase])

  // Start camera on mount
  useEffect(() => {
    startCamera()
    return () => stopCamera()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } },
        audio: false,
      })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
      }
      setCameraReady(true)
    } catch (err) {
      console.error('Camera access denied:', err)
      setError('Camera access denied. Please allow camera permissions.')
    }
  }

  const stopCamera = () => {
    streamRef.current?.getTracks().forEach(t => t.stop())
    streamRef.current = null
    setCameraReady(false)
  }

  const startRecording = useCallback(() => {
    if (!streamRef.current) return

    chunksRef.current = []
    setRecordedBlob(null)
    setRecordedUrl(null)
    setResult(null)
    setError(null)
    setRecordingTime(0)

    const recorder = new MediaRecorder(streamRef.current, {
      mimeType: MediaRecorder.isTypeSupported('video/webm;codecs=vp9')
        ? 'video/webm;codecs=vp9'
        : 'video/webm',
    })

    recorder.ondataavailable = (e) => {
      if (e.data.size > 0) chunksRef.current.push(e.data)
    }

    recorder.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: 'video/webm' })
      setRecordedBlob(blob)
      const url = URL.createObjectURL(blob)
      setRecordedUrl(url)
    }

    recorder.start(100) // collect data every 100ms
    recorderRef.current = recorder
    setRecording(true)

    // Timer
    timerRef.current = setInterval(() => {
      setRecordingTime(prev => prev + 1)
    }, 1000)
  }, [])

  const stopRecording = useCallback(() => {
    recorderRef.current?.stop()
    setRecording(false)
    if (timerRef.current) {
      clearInterval(timerRef.current)
      timerRef.current = null
    }
  }, [])

  const discardRecording = useCallback(() => {
    if (recordedUrl) URL.revokeObjectURL(recordedUrl)
    setRecordedBlob(null)
    setRecordedUrl(null)
    setResult(null)
    setError(null)
    setRecordingTime(0)
  }, [recordedUrl])

  const handleSubmit = async () => {
    if (!recordedBlob) return

    setLoading(true)
    setResult(null)
    setError(null)

    try {
      const formData = new FormData()
      formData.append('video', recordedBlob, 'recording.webm')
      formData.append('level', level.toString())

      const res = await fetch(`${apiBase}/api/hearing-impairment/predict-video`, {
        method: 'POST',
        body: formData,
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.detail || `Server error: ${res.status}`)
      } else {
        setResult(data)
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Network error — is the server running?')
    } finally {
      setLoading(false)
    }
  }

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60).toString().padStart(2, '0')
    const s = (secs % 60).toString().padStart(2, '0')
    return `${m}:${s}`
  }

  const healthStatus = health
    ? health.status === 'healthy' ? 'healthy'
      : health.status === 'unreachable' ? 'unhealthy'
        : 'unknown'
    : 'unknown'

  return (
    <div className="app">
      <header className="header">
        <h1>Sign Language Number Predictor</h1>
        <p>Record a sign language gesture to predict the number</p>
      </header>

      <div className="card">
        {/* Level Selection */}
        <div className="section">
          <span className="section-label">Model Level</span>
          <div className="level-grid">
            {LEVELS.map((l) => (
              <button
                key={l.level}
                className={`level-btn${level === l.level ? ' active' : ''}`}
                onClick={() => { setLevel(l.level); setResult(null); setError(null) }}
              >
                <span className="level-num">{l.level}</span>
                <span className="level-range">{l.range}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Camera / Playback */}
        <div className="section">
          <span className="section-label">
            {recordedUrl ? 'Recorded Video' : 'Camera'}
          </span>
          <div className="camera-container">
            {/* Live camera feed */}
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted
              className="camera-video"
              style={{ display: recordedUrl ? 'none' : 'block' }}
            />

            {/* Playback of recorded video */}
            {recordedUrl && (
              <video
                ref={playbackRef}
                src={recordedUrl}
                controls
                playsInline
                className="camera-video"
              />
            )}

            {/* Recording indicator */}
            {recording && (
              <div className="recording-indicator">
                <span className="rec-dot" />
                <span className="rec-time">{formatTime(recordingTime)}</span>
              </div>
            )}

            {/* Camera not ready overlay */}
            {!cameraReady && !recordedUrl && (
              <div className="camera-overlay">
                <div className="camera-overlay-icon">📷</div>
                <div className="camera-overlay-text">Starting camera...</div>
              </div>
            )}
          </div>

          {/* Camera controls */}
          <div className="camera-controls">
            {!recordedUrl ? (
              <>
                {!recording ? (
                  <button
                    className="rec-btn start"
                    onClick={startRecording}
                    disabled={!cameraReady}
                  >
                    <span className="rec-btn-dot" />
                    Record
                  </button>
                ) : (
                  <button className="rec-btn stop" onClick={stopRecording}>
                    <span className="rec-btn-square" />
                    Stop ({formatTime(recordingTime)})
                  </button>
                )}
              </>
            ) : (
              <div className="playback-controls">
                <button className="control-btn discard" onClick={discardRecording}>
                  ✕ Discard
                </button>
                <button
                  className={`submit-btn${loading ? ' loading' : ''}`}
                  disabled={loading}
                  onClick={handleSubmit}
                >
                  {loading ? 'Processing...' : `Predict (Level ${level})`}
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Result */}
        {result && (
          <div className="result success">
            <div className="result-header">✓ Prediction Complete</div>
            <div className="result-body">
              <div className="result-row">
                <span className="result-label">Predicted Number</span>
                <span className="result-value prediction">{result.prediction}</span>
              </div>
              {result.confidence !== null && (
                <div className="result-row">
                  <span className="result-label">Confidence</span>
                  <span className="result-value">{(result.confidence * 100).toFixed(1)}%</span>
                </div>
              )}
              <div className="result-row">
                <span className="result-label">Level</span>
                <span className="result-value">{level}</span>
              </div>
              <div className="result-row">
                <span className="result-label">Message</span>
                <span className="result-value" style={{ fontSize: '0.75rem', fontWeight: 400 }}>{result.message}</span>
              </div>
            </div>
          </div>
        )}

        {error && (
          <div className="result error">
            <div className="result-header">✗ Error</div>
            <div className="result-error-msg">{error}</div>
          </div>
        )}

        {/* API Config */}
        <div className="api-config">
          <span className="section-label">API Base URL</span>
          <div className="api-input-group">
            <input
              className="api-input"
              value={apiBase}
              onChange={(e) => setApiBase(e.target.value)}
              placeholder="http://localhost:8000"
            />
            <span
              className={`health-badge ${healthStatus}`}
              title={health ? JSON.stringify(health, null, 2) : 'Checking...'}
              onClick={() => {
                setHealth(null)
                fetch(`${apiBase}/api/hearing-impairment/health`)
                  .then(r => r.json())
                  .then(setHealth)
                  .catch(() => setHealth({ status: 'unreachable' }))
              }}
            >
              <span className="health-dot" />
              {healthStatus === 'healthy'
                ? `${health?.loaded_levels?.length}/${health?.total_levels} models`
                : healthStatus === 'unhealthy' ? 'offline'
                  : 'check'}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
