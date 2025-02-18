#Requires Autohotkey v2.0+
; #include <Array>              ; https://github.com/Descolada/AHK-v2-libraries/blob/main/Lib/Array.ahk
; #include <child_process>      ; https://github.com/thqby/ahk2_lib/blob/master/child_process.ahk
; #include <cJSON>              ; https://github.com/G33kDude/cJson.ahk
; #include <OVERLAPPED>         ; https://github.com/thqby/ahk2_lib/blob/master/OVERLAPPED.ahk



/**
 * A class for interacting with Bitwarden Secrets Manager through its CLI.
 * https://bitwarden.com/help/secrets-manager-cli
 *
 * Provides methods for managing secrets and projects, with support for both ID and name-based operations.
 * 
 * Features:
 * - Secret management (create, read, update, delete)
 * - Project management (create, read, update, delete)
 * - Support for batch operations on secrets and projects
 * - Automatic ID resolution from names/keys
 * 
 * @requires Array (Descolada)      @ https://github.com/Descolada/AHK-v2-libraries/blob/main/Lib/Array.ahk
 * @requires child_process (thqby)  @ https://github.com/thqby/ahk2_lib/blob/master/child_process.ahk
 * @requires OVERLAPPED (thqby)     @ https://github.com/thqby/ahk2_lib/blob/master/OVERLAPPED.ahk
 * @requires cJSON (geek)           @ https://github.com/G33kDude/cJson.ahk
 * 
 * @example
 * ; Create a project and add a secret
 * project := bws.create_project("My Project")
 * secret := bws.create_secret("API_KEY", "secret-value", project.id)
 * 
 * ; Retrieve and use a secret
 * api_key := bws.get_secret("API_KEY")
 * 
 * ; Delete multiple secrets
 * bws.delete_secret(["OLD_KEY", "UNUSED_KEY"])
 */

class bws {

    ;; ══════════════════════════════════════════════════════════════════════════
    ;;          constants
    ;; ══════════════════════════════════════════════════════════════════════════

    static exe      := PATH_TO_YOUR_BWS_EXE
    static token    := ADD_YOUR_BWS_TOKEN
    
    ;; ══════════════════════════════════════════════════════════════════════════
    ;;          helpers
    ;; ══════════════════════════════════════════════════════════════════════════

    static quote(str, single_quote:=false) => (q := single_quote ? "'" : '"', q str q)

    /**
     * Executes a BWS CLI command with proper authentication.
     * @param {String} bws_command The command to execute
     * @returns {Object} JSON-parsed response from the BWS CLI
     * @example
     * response := bws.run_command('--version')
     * MsgBox(response['version'])
     */
    static run_command(bws_command) {
        try {
            command := child_process(
                Format('{1} /c {2} {3} --access-token ' this.quote('{4}'),
                    A_ComSpec,
                    this.exe,
                    bws_command,
                    this.token
            ))
            command.Wait()
            return JSON.Load(command.stdout.Read())
        }
        return
    }

    /**
     * Helper method to resolve either an ID or name to an ID
     * @param {String} id_or_name The ID or name to resolve
     * @param {String} type Either 'secret' or 'project'
     * @returns {String|undefined} The resolved ID, undefined if no match was found
     * @throws {Error} If no match is found
     * @example
     * ; Resolve by ID (returns same ID)
     * id := bws.resolve_id('f1fe5978-0aa1-4bb0-949b-b03000e0402a', 'project')
     * ; Resolve by name (returns ID for 'My Project')
     * id := bws.resolve_id('My Project', 'project')
     */
    static resolve_id(id_or_name, type) {
        try {
            if (RegExMatch(id_or_name, 'i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'))
                return id_or_name

            items       := type == 'secret' ? this.get_secrets() : this.get_projects()
            key_field   := type == 'secret' ? 'key' : 'name'
            found_item  := ''

            if (items.Length) {
                items.Find((item) => item[key_field] == id_or_name, &found_item)                
                if (found_item && found_item.Has('id'))
                    return found_item['id']
            }

            throw Error('Could not find ' type ' with name: ' id_or_name)

        } catch as err {
            MsgBox('Error in resolve_id:`n`n' err.Message,'Error', 'IconX')
            return ''
        }
    }

    ;; ══════════════════════════════════════════════════════════════════════════
    ;;          secrets                      
    ;; ══════════════════════════════════════════════════════════════════════════

    /**
     * Retrieves all secrets from Bitwarden Secrets Manager.
     * @returns {Array} Array of secret objects with updated timestamps
     * @example
     * secrets := bws.get_secrets()
     * for secret in secrets
     *     MsgBox(secret['key'] ' was updated on ' secret['updated'])
     */
    static get_secrets() {
        try {
            SECRETS := this.run_command('secret list')
            return SECRETS
        }
        return
    }

    /**
     * Retrieves a specific secret from Bitwarden Secrets Manager.
     * @param {String} id_or_name The ID or key name of the secret to retrieve
     * @param {Boolean} return_value_only If true, returns only the secret value; if false, returns the entire secret object
     * @returns {String|Object} Secret value or complete secret object
     * @example
     * ; Get secret by name
     * api_key := bws.get_secret('API_KEY')
     * ; Get secret by ID
     * secret_info := bws.get_secret('f1fe5978-0aa1-4bb0-949b-b03000e0402a', false)
     */
    static get_secret(id_or_name, return_value_only:=true) {
        try {
            SECRETS := this.get_secrets()
            if !secret_id := this.resolve_id(id_or_name, 'secret')
                return
            SECRETS.Find((secret) => secret['id'] == secret_id, &found_secret)
            return return_value_only ? found_secret['value'] : found_secret
        }
        return
    }

    /**
     * Creates a new secret in Bitwarden Secrets Manager.
     * @param {String} key The key name for the new secret
     * @param {String} value The value for the new secret
     * @param {String} project_id_or_name The ID or name of the project to create the secret in
     * @param {String} note Optional note to attach to the secret
     * @returns {Object} Complete secret object of the newly created secret
     * @example
     * ; Create a new secret with a note
     * new_secret := bws.create_secret('API_KEY', 'secret-value', 'My Project', 'API key for production')
     * MsgBox('Created secret with ID: ' new_secret['id'])
     * 
     * ; Create a new secret without a note
     * new_secret := bws.create_secret('DB_PASSWORD', 'db-pass-value', 'f1fe5978-0aa1-4bb0-949b-b03000e0402a')
     */
    static create_secret(key, value, project_id_or_name, note:='') {
        try {
            if !project_id := this.resolve_id(project_id_or_name, 'project')
                return
            return this.run_command(
                Format('secret create {1} {2} {3}{4}',
                    this.quote(key),
                    this.quote(value),
                    project_id,
                    note ? ' --note ' this.quote(note) : ''
                )
            )
        }
        return
    }

    /**
     * Edits an existing secret in Bitwarden Secrets Manager.
     * @param {String} id_or_name The ID or key name of the secret to edit
     * @param {String} new_value The new value for the secret
     * @param {Boolean} return_value_only If true, returns only the updated value; if false, returns the complete updated secret object
     * @returns {String|Object} Updated secret value or complete updated secret object
     * @example
     * ; Update secret by name
     * new_value := bws.edit_secret('API_KEY', 'new-api-key-value')
     * ; Update secret by ID
     * updated_secret := bws.edit_secret('f1fe5978-0aa1-4bb0-949b-b03000e0402a', 'new-value', false)
     */
    static edit_secret(id_or_name, new_value, return_value_only:=true) {
        try {
            if !secret_id := this.resolve_id(id_or_name, 'secret')
                return
            EDIT_SECRET := this.run_command('secret edit ' secret_id ' --value ' new_value)
            return return_value_only ? EDIT_SECRET['value'] : EDIT_SECRET
        }
        return
    }

    /**
     * Deletes one or more secrets from Bitwarden Secrets Manager.
     * @param {String|Array} ids_or_names Single secret ID/key as string or array of secret IDs/keys
     * @returns {Boolean} True if deletion was successful, False otherwise
     * @example
     * ; Delete by key name
     * success := bws.delete_secret('API_KEY')
     * ; Delete by ID
     * success := bws.delete_secret('be8e0ad8-d545-4017-a55a-b02f014d4158')
     * ; Delete multiple secrets by mix of keys and IDs
     * success := bws.delete_secret(['DB_PASSWORD', 'be8e0ad8-d545-4017-a55a-b02f014d4158'])
     */
    static delete_secret(ids_or_names) {
        try {
            ids_or_names := (Type(ids_or_names) == 'String') ? [ids_or_names] : ids_or_names
            SECRET_IDS := []
            
            for id_or_name in ids_or_names {
                if !resolved_id := this.resolve_id(id_or_name, 'secret')
                    continue
                SECRET_IDS.Push(resolved_id)
            }
            
            if !SECRET_IDS.Length
                return false
                
            return this.run_command('secret delete ' SECRET_IDS.Join(' '))
        }
        return false
    }

    ;; ══════════════════════════════════════════════════════════════════════════
    ;;          projects                     
    ;; ══════════════════════════════════════════════════════════════════════════
    
    /**
     * Retrieves all projects from Bitwarden Secrets Manager.
     * @returns {Array} Array of project objects with updated timestamps
     * @example
     * projects := bws.get_projects()
     * for project in projects
     *     MsgBox(project['name'] ' was created on ' project['created'])
     */
    static get_projects() {
        try return this.run_command('project list')
        return
    }

    /**
     * Retrieves information about a specific project.
     * @param {String} id_or_name The ID or name of the project to retrieve
     * @param {Boolean} return_id_only If true, returns only the project ID; if false, returns the complete project object
     * @returns {String|Object} Project ID or complete project object
     * @example
     * ; Get project by name
     * project_id := bws.get_project('MyProject')
     * ; Get project by ID
     * project_info := bws.get_project('f1fe5978-0aa1-4bb0-949b-b03000e0402a', false)
     */
    static get_project(id_or_name, return_id_only:=true) {
        try {
            PROJECTS := this.get_projects()
            if !project_id := this.resolve_id(id_or_name, 'project') 
                return
            PROJECTS.Find((project) => project['id'] == project_id, &found_project)
            return return_id_only ? found_project['id'] : found_project
        }
        return
    }

    /**
     * Creates a new project in Bitwarden Secrets Manager.
     * @param {String} project_name The name for the new project
     * @returns {Object} Complete project object of the newly created project
     * @example
     * ; Create a new project
     * new_project := bws.create_project('My New Project')
     * MsgBox('Created project with ID: ' new_project['id'])
     */
    static create_project(project_name) {
        try return this.run_command('project create ' this.quote(project_name))
        return
    }

    /**
     * Edits an existing project's name in Bitwarden Secrets Manager.
     * @param {String} id_or_name The ID or name of the project to edit
     * @param {String} new_name The new name for the project
     * @returns {Object} Complete project object with updated information
     * @example
     * ; Edit project by name
     * updated_project := bws.edit_project('Old Project Name', 'New Project Name')
     * ; Edit project by ID
     * updated_project := bws.edit_project('f1fe5978-0aa1-4bb0-949b-b03000e0402a', 'New Name')
     */
    static edit_project(id_or_name, new_name) {
        try {
            if !project_id := this.resolve_id(id_or_name, 'project')
                return
            return this.run_command('project edit ' project_id ' --name ' this.quote(new_name))
        }
        return
    }

    /**
     * Deletes one or more projects from Bitwarden Secrets Manager.
     * @param {String|Array} ids_or_names Single project ID/name as string or array of project IDs/names
     * @returns {Boolean} True if deletion was successful, False otherwise
     * @example
     * ; Delete by name
     * success := bws.delete_project('My Project')
     * ; Delete by ID
     * success := bws.delete_project('f1fe5978-0aa1-4bb0-949b-b03000e0402a')
     * ; Delete multiple projects by mix of names and IDs
     * success := bws.delete_project(['My Project', 'f277fd80-1bd2-4532-94b2-b03000e00c6c'])
     */
    static delete_project(ids_or_names) {
        try {
            ids_or_names := (Type(ids_or_names) == 'String') ? [ids_or_names] : ids_or_names
            PROJECT_IDS := []
            
            for id_or_name in ids_or_names {
                if !resolved_id := this.resolve_id(id_or_name, 'project')
                    continue
                PROJECT_IDS.Push(resolved_id)
            }
            
            if !PROJECT_IDS.Length
                return false
                
            return this.run_command('project delete ' PROJECT_IDS.Join(' '))
        }
        return false
    }
    
}
