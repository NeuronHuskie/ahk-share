#Requires Autohotkey v2.0+
#SingleInstance Force

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;       examples
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
; ╔──────────────────────────────────────────────────╗
; ║                    zip folder                    ║
; ╚──────────────────────────────────────────────────╝
; test_folder := A_Desktop '\test'
; zipper.zip(test_folder, A_Desktop '\test_folder.zip')

; ╔──────────────────────────────────────────────────╗
; ║                     zip file                     ║
; ╚──────────────────────────────────────────────────╝
; test_file   := A_Desktop '\test1.pdf'
; zipper.zip(test_file, A_Desktop '\test_file.zip')

; ; ╔──────────────────────────────────────────────────╗
; ; ║                 zip files array                  ║
; ; ╚──────────────────────────────────────────────────╝
; test_files  := [
;     A_Desktop '\test1.pdf',
;     A_Desktop '\test2.pdf'
; ]
; zipper.zip(test_files, A_Desktop '\test_files.zip')

; ; ╔──────────────────────────────────────────────────╗
; ; ║                      unzip                       ║
; ; ╚──────────────────────────────────────────────────╝
; test_zip    := A_Desktop '\test.zip'
; zipper.unzip(test_zip, A_Desktop '\test_zip_destination')


; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

class zipper {
    static create_empty_zip(zip_path) {
        try {
            file := FileOpen(zip_path, 'w')
            file.Write('PK' . Chr(5) . Chr(6))
            file.RawWrite(Buffer(18, 0), 18)
            file.Close()
        } catch as err {
            throw Error('Error creating zip file: ' . err.Message)
        }
    }

    static zip(files_to_zip, output_zip) {
        if !FileExist(output_zip)
            this.create_empty_zip(output_zip)

        try 
            zip_contents := ComObject('Shell.Application').Namespace(output_zip)
        catch as err
            throw Error('Error accessing zip file: ' . err.Message)

        zipped      := 0
        is_array    := Type(files_to_zip) = 'Array' ? true : false
        is_array    ? this.add_array_to_zip(files_to_zip, zip_contents, &zipped) : this.add_to_zip(files_to_zip, zip_contents, &zipped)

        ToolTip()
    }

    static add_array_to_zip(files, zip_contents, &zipped) {
        for file in files
            this.add_to_zip(file, zip_contents, &zipped)
    }

    static add_to_zip(path, zip_contents, &zipped) {
        if InStr(FileExist(path), 'D') {
            path .= SubStr(path, -1) = '\' ? '*.*' : '\*.*'
            Loop Files, path, 'FD' {
                zipped++
                ToolTip('Zipping ' . A_LoopFileName . ' ..')
                zip_contents.CopyHere(A_LoopFilePath, 4|16)
                while (zip_contents.Items().Count != zipped)
                    Sleep(10)
            }
        } else {
            zipped++
            ToolTip('Zipping ' . path . ' ..')
            zip_contents.CopyHere(path, 4|16)
            while (zip_contents.Items().Count != zipped)
                Sleep(10)
        }
    }

    static unzip(zip_file, destination) {
        if !FileExist(zip_file)
            throw Error('Zip file does not exist: ' . zip_file)

        if !FileExist(destination)
            DirCreate(destination)

        fso  := ComObject('Scripting.FileSystemObject')
        src  := ComObject('Shell.Application').Namespace(zip_file)
        dest := ComObject('Shell.Application').Namespace(destination)

        try {
            items := src.Items()
            total_items := items.Count
            current_item := 0

            for item in items {
                current_item++
                ToolTip('Extracting ' . item.Name . ' (' . current_item . '/' . total_items . ')')
                dest.CopyHere(item, 4|16)
            }
        } catch as err {
            throw Error('Error during extraction: ' . err.Message)
        }

        ToolTip()
    }
}
