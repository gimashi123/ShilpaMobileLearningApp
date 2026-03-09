// import fs from "fs";
// import path from "path";
//
// const uploadRoot = path.join(process.cwd(), "uploads");
//
// export const saveFile = async (
//     buffer: Buffer,
//     folder: string,
//     filename: string
// ) => {
//
//     const dir = path.join(uploadRoot, folder);
//
//     if (!fs.existsSync(dir)) {
//         fs.mkdirSync(dir, { recursive: true });
//     }
//
//     const filePath = path.join(dir, filename);
//
//     fs.writeFileSync(filePath, buffer);
//
//     return `/uploads/${folder}/${filename}`;
// };
//
// export const getFilePath = (folder: string, filename: string) => {
//     return path.join(uploadRoot, folder, filename);
// };