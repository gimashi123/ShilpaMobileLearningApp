import { Schema, model, Document } from 'mongoose';
import bcrypt from 'bcryptjs';


export type Role = 'student' | 'parent' | 'teacher' | 'admin';


interface StudentProfile { grade?: number; age?: number; }


export interface IUser extends Document {
    name: string;
    email: string;
    password: string;
    role: Role;
    student?: StudentProfile;
    comparePassword(candidate: string): Promise<boolean>;
}


const StudentProfileSchema = new Schema<StudentProfile>(
    {
        grade: { type: Number, min: 1, max: 13 },
        age: { type: Number }
    },
    { _id: false }
);


const BlindSchema = new Schema<IUser>(
    {
        name: { type: String, required: true, trim: true },
        email: { type: String, required: true, lowercase: true, unique: true, index: true },
        password: { type: String, required: true, minlength: 6, select: false },
        role: { type: String, enum: ['student', 'parent', 'teacher', 'admin'], default: 'student', required: true },
        student: StudentProfileSchema
    },
    { timestamps: true }
);


BlindSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    const salt = await bcrypt.genSalt(10);
    // @ts-ignore - Mongoose typing
    this.password = await bcrypt.hash(this.password, salt);
    next();
});


BlindSchema.methods.comparePassword = function (candidate: string) {
    // @ts-ignore
    return bcrypt.compare(candidate, this.password);
}


export default model<IUser>(' BlindSchema', BlindSchema);