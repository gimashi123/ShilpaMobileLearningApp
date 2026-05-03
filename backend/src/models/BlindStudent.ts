import { Schema, model, Document } from 'mongoose';
import bcrypt from 'bcryptjs';

export type Role = 'student' | 'parent' | 'teacher' | 'admin';
export type DisabilityType = 'visual' | 'hearing' | 'physical' | 'cognitive';

interface StudentProfile {
    grade?: number;
    age?: number;
}

export interface IUser extends Document {
    name: string;
    email: string;
    password: string;
    role: Role;
    student?: StudentProfile;
    disabilityType?: DisabilityType;
    signGameXp: number;
    comparePassword(candidate: string): Promise<boolean>;
}

const StudentProfileSchema = new Schema<StudentProfile>(
    {
        grade: { type: Number, min: 1, max: 13 },
        age: { type: Number },
    },
    { _id: false }
);

const UserSchema = new Schema<IUser>(
    {
        name: { type: String, required: true, trim: true },

        email: {
            type: String,
            required: true,
            lowercase: true,
            unique: true,
            index: true,
        },

        password: {
            type: String,
            required: true,
            minlength: 6,
            select: false, // 🔥 IMPORTANT (security)
        },

        role: {
            type: String,
            enum: ['student', 'parent', 'teacher', 'admin'],
            default: 'student',
            required: true,
        },

        student: StudentProfileSchema,

        disabilityType: {
            type: String,
            enum: ['visual', 'hearing', 'physical', 'cognitive'],
            required: function (this: IUser) {
                return this.role === 'student';
            },
        },

        signGameXp: {
            type: Number,
            default: 0,
        },
    },
    { timestamps: true }
);

// 🔐 Hash password
UserSchema.pre<IUser>('save', async function (next) {
    if (!this.isModified('password')) return next();

    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// 🔑 Compare password
UserSchema.methods.comparePassword = async function (candidate: string) {
    return bcrypt.compare(candidate, this.password);
};

export default model<IUser>('User', UserSchema);