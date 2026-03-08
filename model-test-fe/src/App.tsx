import { useState, useRef, useCallback, useEffect } from 'react'
import './App.css'

const LEVELS = [
  { level: 1, range: '1–10' },
  { level: 2, range: '11–20' },
  { level: 3, range: '24–70' },
  { level: 4, range: '75-100' },
]

const DEFAULT_API = 'http://localhost:8000'

// ─── Types ───────────────────────────────────────────────────────────────────

interface HearingResult {
  prediction: number
  confidence: number | null
  success: boolean
  message: string
}

interface BrailleResult {
  number: number
  digits: number[]
  confidences: number[]
  success: boolean
  message: string
}

interface HealthResult {
  status: string
  loaded_levels?: number[]
  total_levels?: number
  error?: string
}

// ─── Hearing Impairment Section ───────────────────────────────────────────────

function HearingSection({ apiBase }: { apiBase: string }) {
  const [level, setLevel] = useState(1)
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<HearingResult | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Video source tab: 'record' | 'upload'
  const [videoTab, setVideoTab] = useState<'record' | 'upload'>('record')

  // Recording state
  const [cameraReady, setCameraReady] = useState(false)
  const [recording, setRecording] = useState(false)
  const [recordedBlob, setRecordedBlob] = useState<Blob | null>(null)
  const [recordedUrl, setRecordedUrl] = useState<string | null>(null)
  const [recordingTime, setRecordingTime] = useState(0)

  // Upload state
  const [uploadedFile, setUploadedFile] = useState<File | null>(null)
  const [uploadedUrl, setUploadedUrl] = useState<string | null>(null)

  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Start camera when record tab is active
  useEffect(() => {
    if (videoTab === 'record') {
      startCamera()
    } else {
      stopCamera()
    }
    return () => stopCamera()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [videoTab])

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } },
        audio: false,
      })
      streamRef.current = stream
      if (videoRef.current) videoRef.current.srcObject = stream
      setCameraReady(true)
    } catch {
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
    recorder.ondataavailable = (e) => { if (e.data.size > 0) chunksRef.current.push(e.data) }
    recorder.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: 'video/webm' })
      setRecordedBlob(blob)
      setRecordedUrl(URL.createObjectURL(blob))
    }
    recorder.start(100)
    recorderRef.current = recorder
    setRecording(true)
    timerRef.current = setInterval(() => setRecordingTime(p => p + 1), 1000)
  }, [])

  const stopRecording = useCallback(() => {
    recorderRef.current?.stop()
    setRecording(false)
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null }
  }, [])

  const discardRecording = useCallback(() => {
    if (recordedUrl) URL.revokeObjectURL(recordedUrl)
    setRecordedBlob(null)
    setRecordedUrl(null)
    setResult(null)
    setError(null)
    setRecordingTime(0)
  }, [recordedUrl])

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] ?? null
    if (uploadedUrl) URL.revokeObjectURL(uploadedUrl)
    setUploadedFile(file)
    setUploadedUrl(file ? URL.createObjectURL(file) : null)
    setResult(null)
    setError(null)
  }

  const discardUpload = () => {
    if (uploadedUrl) URL.revokeObjectURL(uploadedUrl)
    setUploadedFile(null)
    setUploadedUrl(null)
    setResult(null)
    setError(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const handleSubmit = async () => {
    const blob = videoTab === 'record' ? recordedBlob : uploadedFile
    if (!blob) return

    setLoading(true)
    setResult(null)
    setError(null)

    try {
      const formData = new FormData()
      const filename = videoTab === 'upload' && uploadedFile
        ? uploadedFile.name
        : 'recording.webm'
      formData.append('video', blob, filename)
      formData.append('level', level.toString())

      const res = await fetch(`${apiBase}/api/hearing-impairment/predict-video`, {
        method: 'POST',
        body: formData,
      })
      const data = await res.json()
      if (!res.ok) setError(data.detail || `Server error: ${res.status}`)
      else setResult(data)
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

  const hasVideo = videoTab === 'record' ? !!recordedUrl : !!uploadedUrl
  const canSubmit = hasVideo && !loading

  return (
    <div>
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

      {/* Video Source Tabs */}
      <div className="section">
        <span className="section-label">Video Source</span>
        <div className="source-tabs">
          <button
            className={`source-tab${videoTab === 'record' ? ' active' : ''}`}
            onClick={() => { setVideoTab('record'); setResult(null); setError(null) }}
          >
            🎥 Record
          </button>
          <button
            className={`source-tab${videoTab === 'upload' ? ' active' : ''}`}
            onClick={() => { setVideoTab('upload'); setResult(null); setError(null) }}
          >
            📁 Upload File
          </button>
        </div>
      </div>

      {/* Record Tab */}
      {videoTab === 'record' && (
        <div className="section">
          <span className="section-label">{recordedUrl ? 'Recorded Video' : 'Camera'}</span>
          <div className="camera-container">
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted
              className="camera-video"
              style={{ display: recordedUrl ? 'none' : 'block' }}
            />
            {recordedUrl && (
              <video src={recordedUrl} controls playsInline className="camera-video" />
            )}
            {recording && (
              <div className="recording-indicator">
                <span className="rec-dot" />
                <span className="rec-time">{formatTime(recordingTime)}</span>
              </div>
            )}
            {!cameraReady && !recordedUrl && (
              <div className="camera-overlay">
                <div className="camera-overlay-icon">📷</div>
                <div className="camera-overlay-text">Starting camera...</div>
              </div>
            )}
          </div>
          <div className="camera-controls">
            {!recordedUrl ? (
              <>
                {!recording ? (
                  <button className="rec-btn start" onClick={startRecording} disabled={!cameraReady}>
                    <span className="rec-btn-dot" /> Record
                  </button>
                ) : (
                  <button className="rec-btn stop" onClick={stopRecording}>
                    <span className="rec-btn-square" /> Stop ({formatTime(recordingTime)})
                  </button>
                )}
              </>
            ) : (
              <div className="playback-controls">
                <button className="control-btn discard" onClick={discardRecording}>✕ Discard</button>
                <button
                  className={`submit-btn${loading ? ' loading' : ''}`}
                  disabled={!canSubmit}
                  onClick={handleSubmit}
                >
                  {loading ? 'Processing...' : `Predict (Level ${level})`}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Upload Tab */}
      {videoTab === 'upload' && (
        <div className="section">
          <span className="section-label">Upload Video File</span>
          {!uploadedUrl ? (
            <label className="upload-zone" htmlFor="hearing-video-upload">
              <span className="upload-icon">🎬</span>
              <span className="upload-text">Click to select a video file</span>
              <span className="upload-hint">MP4, MOV, AVI, MKV, WebM</span>
              <input
                id="hearing-video-upload"
                ref={fileInputRef}
                type="file"
                accept="video/mp4,video/quicktime,video/avi,video/x-matroska,video/webm,video/*"
                onChange={handleFileChange}
                style={{ display: 'none' }}
              />
            </label>
          ) : (
            <>
              <div className="camera-container">
                <video src={uploadedUrl} controls playsInline className="camera-video" />
              </div>
              <div className="upload-file-info">
                <span className="upload-file-name">📎 {uploadedFile?.name}</span>
                <span className="upload-file-size">
                  {uploadedFile ? (uploadedFile.size / 1024 / 1024).toFixed(1) + ' MB' : ''}
                </span>
              </div>
              <div className="playback-controls" style={{ marginTop: '0.75rem' }}>
                <button className="control-btn discard" onClick={discardUpload}>✕ Remove</button>
                <button
                  className={`submit-btn${loading ? ' loading' : ''}`}
                  disabled={!canSubmit}
                  onClick={handleSubmit}
                >
                  {loading ? 'Processing...' : `Predict (Level ${level})`}
                </button>
              </div>
            </>
          )}
        </div>
      )}

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
    </div>
  )
}

// ─── Braille / Visual Impairment Section ─────────────────────────────────────

function BrailleSection({ apiBase }: { apiBase: string }) {
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<BrailleResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? [])
    if (!files.length) return

    // Revoke old previews
    previewUrls.forEach(u => URL.revokeObjectURL(u))

    setImages(files)
    setPreviewUrls(files.map(f => URL.createObjectURL(f)))
    setResult(null)
    setError(null)
  }

  const removeImage = (idx: number) => {
    URL.revokeObjectURL(previewUrls[idx])
    const newImgs = images.filter((_, i) => i !== idx)
    const newUrls = previewUrls.filter((_, i) => i !== idx)
    setImages(newImgs)
    setPreviewUrls(newUrls)
    setResult(null)
    setError(null)
    if (newImgs.length === 0 && fileInputRef.current) fileInputRef.current.value = ''
  }

  const handleSubmit = async () => {
    if (!images.length) return
    setLoading(true)
    setResult(null)
    setError(null)

    try {
      const formData = new FormData()
      images.forEach(img => formData.append('images', img, img.name))

      const res = await fetch(`${apiBase}/api/visual-impairment/predict-image`, {
        method: 'POST',
        body: formData,
      })
      const data = await res.json()
      if (!res.ok) setError(data.detail || `Server error: ${res.status}`)
      else setResult(data)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Network error — is the server running?')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      {/* Info banner */}
      <div className="braille-info">
        <span className="braille-info-icon">ℹ️</span>
        <p>
          Upload <strong>one image per digit</strong>. For numbers ≥ 10, upload multiple images
          in order — e.g. an image of <em>1</em> then an image of <em>0</em> to predict <strong>10</strong>.
        </p>
      </div>

      {/* Image upload */}
      <div className="section">
        <span className="section-label">Braille Digit Image(s)</span>
        <label className="upload-zone" htmlFor="braille-image-upload">
          <span className="upload-icon">🔡</span>
          <span className="upload-text">Click to select image(s)</span>
          <span className="upload-hint">JPEG, PNG, BMP, WebP — one per digit</span>
          <input
            id="braille-image-upload"
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/jpg,image/png,image/bmp,image/webp,image/tiff"
            multiple
            onChange={handleImageChange}
            style={{ display: 'none' }}
          />
        </label>

        {/* Previews */}
        {previewUrls.length > 0 && (
          <div className="braille-previews">
            {previewUrls.map((url, idx) => (
              <div key={idx} className="braille-preview-item">
                <div className="braille-preview-badge">{idx + 1}</div>
                <img src={url} alt={`Digit ${idx + 1}`} className="braille-preview-img" />
                <button
                  className="braille-remove-btn"
                  onClick={() => removeImage(idx)}
                  title="Remove"
                >×</button>
                <div className="braille-preview-name">{images[idx]?.name}</div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Submit */}
      {images.length > 0 && (
        <div className="playback-controls">
          <button
            className="control-btn discard"
            onClick={() => {
              previewUrls.forEach(u => URL.revokeObjectURL(u))
              setImages([])
              setPreviewUrls([])
              setResult(null)
              setError(null)
              if (fileInputRef.current) fileInputRef.current.value = ''
            }}
          >
            ✕ Clear All
          </button>
          <button
            className={`submit-btn${loading ? ' loading' : ''}`}
            disabled={loading}
            onClick={handleSubmit}
          >
            {loading ? 'Predicting...' : `Predict${images.length > 1 ? ` (${images.length} digits)` : ''}`}
          </button>
        </div>
      )}

      {/* Result */}
      {result && (
        <div className="result success">
          <div className="result-header">✓ Prediction Complete</div>
          <div className="result-body">
            <div className="result-row">
              <span className="result-label">Predicted Number</span>
              <span className="result-value prediction">{result.number}</span>
            </div>
            {result.digits.length > 1 && (
              <div className="result-row">
                <span className="result-label">Digits</span>
                <span className="result-value">{result.digits.join(' → ')}</span>
              </div>
            )}
            <div className="result-row">
              <span className="result-label">Confidences</span>
              <span className="result-value">
                {result.confidences.map(c => (c * 100).toFixed(1) + '%').join(', ')}
              </span>
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
    </div>
  )
}

// ─── App ─────────────────────────────────────────────────────────────────────

export default function App() {
  const [apiBase, setApiBase] = useState(DEFAULT_API)
  const [health, setHealth] = useState<HealthResult | null>(null)
  const [activeTab, setActiveTab] = useState<'hearing' | 'braille'>('hearing')

  useEffect(() => {
    const check = async () => {
      try {
        const res = await fetch(`${apiBase}/api/hearing-impairment/health`)
        setHealth(await res.json())
      } catch {
        setHealth({ status: 'unreachable' })
      }
    }
    check()
  }, [apiBase])

  const healthStatus = health
    ? health.status === 'healthy' ? 'healthy'
      : health.status === 'unreachable' ? 'unhealthy'
        : 'unknown'
    : 'unknown'

  return (
    <div className="app">
      <header className="header">
        <h1>Shilpa ML Model Tester</h1>
        <p>Test hearing impairment sign prediction & visual Braille digit recognition</p>
      </header>

      <div className="card">
        {/* Main tab switcher */}
        <div className="main-tabs">
          <button
            className={`main-tab${activeTab === 'hearing' ? ' active' : ''}`}
            onClick={() => setActiveTab('hearing')}
          >
            🤟 Hearing Impairment
          </button>
          <button
            className={`main-tab${activeTab === 'braille' ? ' active' : ''}`}
            onClick={() => setActiveTab('braille')}
          >
            👁️ Braille Numbers
          </button>
        </div>

        {activeTab === 'hearing' && <HearingSection apiBase={apiBase} />}
        {activeTab === 'braille' && <BrailleSection apiBase={apiBase} />}

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
