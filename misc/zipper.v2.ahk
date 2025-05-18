#Requires Autohotkey v2.0+

/**
 * ZIPPER
 * 
 * A comprehensive class for creating and extracting ZIP archives using 7-Zip command line tool.
 * Automatically detects file selection from Windows Explorer and handles both single and multiple
 * file operations with intelligent archive type detection.
 * 
 * @requires AutoHotkey v2.0+
 * @requires 7-Zip command line tool (7za.exe)
 * @requires Explorer\PathX library - https://www.autohotkey.com/boards/viewtopic.php?style=19&f=83&t=120582
 * @requires Explorer\Explorer_GetSelection library - https://www.autohotkey.com/boards/viewtopic.php?p=529074#p529074
 * 
 * @example
 * ; Create a new zip from selected files in Explorer
 * zipper := ZIPPER()
 * 
 * @example
 * ; Create zip with custom output path
 * zipper := ZIPPER(, "C:\MyArchives\backup.zip")
 * 
 * @example
 * ; Zip specific files
 * files := ["C:\file1.txt", "C:\file2.doc"]
 * zipper := ZIPPER(files, "C:\output.zip")
 * 
 * @example
 * ; Extract archive (automatic detection)
 * zipper := ZIPPER(["C:\archive.zip"])
 */
class ZIPPER {
     /**
     * Path to 7-Zip command line executable (7za.exe)
     * @type {String}
     * @static
     * @default A_ProgramFiles '\7-Zip\7za.exe'
     */
    static exe_path := A_ProgramFiles '\7-Zip\7za.exe'   
    
   /**
     * Constructor - Initializes ZIPPER instance and performs archive operation
     * 
     * Creates a new ZIPPER instance that automatically detects whether to compress or extract
     * based on file selection. The constructor initializes the following instance variables:
     * - this.selection: Array of file paths to process
     * - this.exe: File extension of the first selected item
     * - this.folder: Parent folder path of the first selected item  
     * - this.filename: Filename without extension of the first selected item
     * 
     * Operation Logic:
     * - If selection is empty, gets current Explorer selection via Explorer_GetSelection()
     * - For single file selection with archive extension (.zip, .7z, .rar, .tar), performs extraction
     * - For all other cases (single non-archive file or multiple files), performs compression
     * - If output_zip is not provided, prompts user with InputBox for zip filename
     * 
     * @param {String|Array} [selection=''] - File paths to process. If empty, uses Explorer selection
     * @param {String} [output_zip=''] - Output path for zip file. If empty, prompts user for input
     * 
     * @throws {Error} When 7-Zip executable is not found
     * @throws {Error} When required libraries are not available
     * 
     * @example
     * ; Process current Explorer selection
     * zipper := ZIPPER()
     * 
     * @example
     * ; Create zip from specific files
     * files := ["C:\Documents\file1.txt", "C:\Documents\file2.pdf"]
     * zipper := ZIPPER(files, "C:\Backup\documents.zip")
     * 
     * @example
     * ; Extract archive to default location
     * zipper := ZIPPER(["C:\Archives\backup.zip"])
     * 
     * @example
     * ; Let user choose zip filename for current selection
     * zipper := ZIPPER("", "")  ; Will prompt for filename
     */
    __New(selection:='', output_zip:='') {
        this.selection  := selection ? selection : StrSplit(Explorer_GetSelection(,1), '`n')
        this.exe        := PathX(this.selection[1]).Ext
        this.folder     := PathX(this.selection[1]).Folder
        this.filename   := PathX(this.selection[1]).Fname

        if this.selection.Length == 1 {
            InStrList(this.exe, ['.zip', '.7z', '.rar', '.tar'])
                ? ZIPPER.unzip(this.selection[1], this.folder '\' this.filename)
                : ZIPPER.zip(this.selection, output_zip ? output_zip : this.folder '\' inputbox('Enter the filename for the zip file:`n`n' PathX(this.selection[1]).Fname, 'ZIPPER').value)
        } else {
            ZIPPER.zip(this.selection, output_zip ? output_zip : this.folder '\' inputbox('Enter the filename for the zip file:`n`n' PathX(this.selection[1]).Fname, 'ZIPPER').value)
        }

    }

     /**
     * Creates a ZIP archive from specified input files or folders
     * 
     * Compresses single files, multiple files, or entire directories into a ZIP archive
     * using 7-Zip command line tool. Automatically appends .zip extension if not present.
     * 
     * @param {String|Array} input - Path(s) to files/folders to compress
     * @param {String} output_zip - Path for the output ZIP file
     * 
     * @returns {String|Boolean} Path to created ZIP file on success, false on failure
     * 
     * @throws {Error} When 7-Zip executable is not found
     * 
     * @static
     * 
     * @example
     * ; Zip a single file
     * result := ZIPPER.zip("C:\document.txt", "C:\backup.zip")
     * 
     * @example
     * ; Zip multiple files
     * files := ["C:\file1.txt", "C:\file2.doc", "C:\file3.pdf"]
     * result := ZIPPER.zip(files, "C:\archive.zip")
     * 
     * @example
     * ; Zip a folder
     * result := ZIPPER.zip("C:\MyFolder", "C:\folder_backup.zip")
     */
    static zip(input, output_zip) {

        ToolTip('Zipping ' output_zip)

        output_zip := SubStr(output_zip, -4) == '.zip' ? output_zip : output_zip '.zip'

        if !FileExist(this.exe_path)
            throw Error('7-Zip executable not found at: ' this.exe_path)

        output_zip := PathX(output_zip).Ext ? output_zip : output_zip '.zip'

        if Type(input) = 'Array' {
            input_list := ''
            for item in input
                input_list .= ' "' item '"'
        } else {
            input_list := ' "' input '"'
        }

        zip_command := Format('"{1}" a -tzip "{2}"{3}', this.exe_path, output_zip, input_list)
        
        try {
            RunWait(zip_command, , 'Hide')
            ToolTip()
            return output_zip
        } catch as err {
            ToolTip()
            MsgBox('Error zipping file(s): ' err.Message, 'ZIPPER Error', 16)
            return false
        }
    }

     /**
     * Extracts files from a ZIP or other supported archive format
     * 
     * Extracts contents of archive files (.zip, .7z, .rar, .tar, etc.) to specified
     * destination folder. Creates destination directory if it doesn't exist.
     * 
     * @param {String} zip_file - Path to the archive file to extract
     * @param {String} [destination=''] - Extraction destination. If empty, uses archive's directory
     * 
     * @returns {String|Boolean} Extraction destination path on success, false on failure
     * 
     * @throws {Error} When 7-Zip executable is not found
     * @throws {Error} When archive file is not found
     * 
     * @static
     * 
     * @example
     * ; Extract to same directory as archive
     * result := ZIPPER.unzip("C:\backup.zip")
     * 
     * @example
     * ; Extract to specific directory
     * result := ZIPPER.unzip("C:\backup.zip", "C:\Extracted")
     * 
     * @example
     * ; Extract different archive formats
     * ZIPPER.unzip("C:\archive.7z", "C:\Output")
     * ZIPPER.unzip("C:\data.rar", "C:\Output")
     */
    static unzip(zip_file, destination := '') {

        ToolTip('Extracting ' PathX(zip_file).File)

        if !FileExist(this.exe_path)
            throw Error('7-Zip executable not found at: ' this.exe_path)

        if !FileExist(zip_file)
            throw Error('Zip file not found: ' zip_file)

        if destination = ''
            destination := PathX(zip_file).Dir

        if !DirExist(destination)
            DirCreate(destination)

        unzip_command := Format('"{1}" x "{2}" -o"{3}" -y', this.exe_path, zip_file, destination)

        try {
            RunWait(unzip_command, , 'Hide')
            ToolTip()
            return destination
        } catch as err {
            ToolTip()
            MsgBox('Error unzipping file: ' err.Message, 'ZIPPER Error', 16)
            return false
        }
    }

    /**
     * Checks if any string in an array contains any of the specified substrings
     * 
     * Utility method for searching multiple strings for multiple patterns.
     * Supports nested arrays for complex pattern matching scenarios.
     * 
     * @param {String|Array} str - String(s) to search in
     * @param {Array} list - Patterns to search for (supports nested arrays)
     * 
     * @returns {Boolean} True if any pattern is found in any string, false otherwise
     * 
     * @static
     * 
     * @example
     * ; Check file extension
     * result := ZIPPER.InStrList("file.zip", [".zip", ".rar"])  ; Returns true
     * 
     * @example
     * ; Check multiple strings
     * files := ["document.pdf", "archive.zip"]
     * result := ZIPPER.InStrList(files, [".zip", ".7z"])  ; Returns true
     * 
     * @example
     * ; Nested pattern arrays
     * result := ZIPPER.InStrList("test.txt", [[".doc", ".txt"], [".zip"]])  ; Returns true
     */
    static InStrList(str, list*) {
        if !IsObject(str)
            str := [str]
        
        for each, value in str {
            for i, item in list {
                if IsObject(item) {
                    for subitem in item {
                        if InStr(value, subitem)
                            return true
                    }
                } else {
                    if InStr(value, item)
                        return true
                }
            }
        }
        return false
    }

}
