<template>
  <div class="card">
    <div class="card-content">
      <div class="media">
        <div class="media-content">
          <div class="columns">
            <div class="column">
              <div class="field is-grouped">
                <div class="control">
                  <div class="select is-small">
                    <select class="database-selection"
                            v-model="selectedDB"
                            @change="switchDB">
                      <option v-for="db in databases"
                              :key="db"
                              :value="db">
                        {{ db }}
                      </option>
                    </select>
                  </div>
                </div>

                <p class="control">
                  <button class="button is-small fork-database-button"
                          @click="forkDB"
                          title="Duplicate Database">
                    <span class="icon is-small">
                      <i class="fas fa-clone"></i>
                    </span>
                  </button>
                </p>

                <p class="control">
                  <a class="button is-small"
                     @click="downloadDB"
                     title="Download Database x">
                    <span class="icon is-small">
                      <i class="fas fa-download"></i>
                    </span>
                  </a>
                </p>

                <p class="control">
                  <button class="button is-small new-database-button"
                          @click="addNewDB()"
                          title="Add New Database">
                    <span class="icon is-small">
                      <i class="fas fa-plus"></i>
                    </span>
                  </button>
                </p>

                <p class="control">
                  <button class="button is-small has-text-danger delete-database-button"
                          @click="deleteDB()"
                          title="Delete Database"
                          :disabled="selectedDB === defaultDBName || databases.length <= 1">
                    <span class="icon is-small">
                      <i class="fas fa-trash"></i>
                    </span>
                  </button>
                </p>
              </div>
            </div>
            <div class="column">
              <div class="field is-grouped is-pulled-right">
                <div class="control">
                  <div class="select is-small">
                    <select class="key-selection"
                            v-model="selectedKey"
                            @change="switchKey">
                      <option v-for="key in keys"
                              :key="key"
                              :value="key">
                        {{ key }}
                      </option>
                    </select>
                  </div>
                </div>

                <p class="control">
                  <button class="button is-small fork-key-button"
                          @click="forkKey"
                          title="Duplicate Key">
                    <span class="icon is-small">
                      <i class="fas fa-clone"></i>
                    </span>
                  </button>
                </p>

                <p class="control">
                  <a class="button is-small"
                     @click="downloadKey"
                     title="Download Key x">
                    <span class="icon is-small">
                      <i class="fas fa-download"></i>
                    </span>
                  </a>
                </p>

                <p class="control">
                  <button class="button is-small new-key-button"
                          @click="addNewKey()"
                          title="Add New Key">
                    <span class="icon is-small">
                      <i class="fas fa-plus"></i>
                    </span>
                  </button>
                </p>

                <p class="control">
                  <button class="button is-small save-button"
                          @click="saveChanges"
                          title="Save changes"
                          :disabled="!isFormValid">
                    <span class="icon is-small">
                      <i class="fas fa-save"></i>
                    </span>
                  </button>
                </p>

                <p class="control">
                  <button class="button is-small has-text-danger delete-key-button"
                          @click="deleteKey()"
                          title="Delete Key"
                          :disabled="(selectedDB === defaultDBName && selectedKey === defaultKeyName) || keys.length <= 1">
                    <span class="icon is-small">
                      <i class="fas fa-trash"></i>
                    </span>
                  </button>
                </p>

              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="content">
        <hr/>
        <div class="card">
          <div class="card-content">
            <div class="content">
              <div class="field">
                <label class="label">Database</label>
                <div class="control">
                  <input class="input is-small is-fullwidth database-name-input"
                         @input="validateInput($event, isSelectedDBNewNameValid)"
                         type="text"
                         placeholder="Database name"
                         v-model="dbNameInput"
                         :disabled="selectedDB === defaultDBName">
                </div>
              </div>
            </div>

            <div class="content">
              <div class="field">
                <label class="label">Key</label>
                <div class="control">
                  <input class="input is-small is-fullwidth key-name-input"
                         @input="validateInput($event, isSelectedKeyNewNameValid)"
                         type="text"
                         placeholder="Key name"
                         v-model="keyNameInput"
                         :disabled="selectedDB === defaultDBName && selectedKey === defaultKeyName">
                </div>
              </div>
            </div>

            <div class="content">
              <div class="field">
                <label class="label">Document</label>
                <div class="control">
                  <textarea
                      @input="validateInput($event, isNewDocumentValid)"
                      rows="20"
                      class="is-family-monospace textarea document-input"
                      v-model="document"
                  >
                  </textarea>
                </div>
              </div>
            </div>
          </div>
        </div>
        <hr/>
        <git-history :gitLog.sync="gitLog"
                     :apiPath.sync="gitAPIPath"
                     @restore-version="restoreGitVersion"></git-history>
      </div>
    </div>
  </div>
</template>

<script>

import DatasetsUtils from '@/assets/DatasetsUtils.js'
import Utils from '@/assets/Utils.js'
import GitHistory from '@/components/GitHistory'
import RequestsUtils from '@/assets/RequestsUtils'

export default {

  name: 'DBEditor',
  props: {},
  components: {
    GitHistory
  },
  data() {
    return {
      databases: [],
      selectedDB: null,
      dbNameInput: '',
      defaultDBName: 'system',

      keys: [],
      selectedKey: null,
      keyNameInput: '',
      defaultKeyName: 'publishinfo',

      selectedDBData: null,
      document: null,

      gitLog: [],

      apiRoot: DatasetsUtils.ConfAPIRoot,
      apiVersion: DatasetsUtils.ConfAPIVersion,
    }
  },
  computed: {

    gitAPIPath() {
      return `${this.apiRoot}/${this.apiVersion}/db/${this.selectedDB}/k/${this.selectedKey}/v/`
    },

    isFormValid() {
      return this.isSelectedDBNewNameValid && this.isSelectedKeyNewNameValid && this.isNewDocumentValid
    },

    isSelectedDBNewNameValid() {
      const newName = this.dbNameInput?.trim()
      const isDBNameEmpty = newName === ''
      const isDBNameDuplicate = this.databases.includes(newName) ? this.selectedDB !== newName : false
      return !isDBNameEmpty && !isDBNameDuplicate
    },

    isSelectedKeyNewNameValid() {
      const newName = this.keyNameInput?.trim()
      const isKeyNameEmpty = newName === ''
      const isKeyNameDuplicate = this.keys.includes(newName) ? this.selectedKey !== newName : false
      return !isKeyNameEmpty && !isKeyNameDuplicate
    },

    isNewDocumentValid() {
      try {
        JSON.parse(this.document)
      } catch {
        return false
      }
      return true
    },

  },

  methods: {

    validateInput(event, validator) {
      Utils.validateInput(event, validator)
    },

    loadDBs() {
      RequestsUtils.sendRequest('GET', 'db/').then((response) => {
        this.databases = response.data
        console.log('Databases: ', this.databases)
        this.loadFirstDB()
      })
    },

    loadFirstDB() {
      const db = this.databases[0]
      if (db) {
        this.loadDB(db)
      } else {
        console.log(`failed loading database, none are present!`)
      }
    },

    async loadDB(db) {
      this.selectedDB = db
      this.dbNameInput = this.selectedDB
      this.selectedDBData = (await RequestsUtils.sendRequest('GET', `db/${this.selectedDB}/`)).data
      this.initDBKeys(this.selectedDB)
    },

    saveDB(db = this.selectedDB, data) {
      if (!data) {
        data = {key: {}}
      }

      return RequestsUtils.sendRequest('PUT', `db/${db}/`, data, `Database [${db}] saved!`, `Failed saving database [${db}]!`)
    },

    switchDB() {
      this.loadDB(this.selectedDB)
    },

    deleteDB(db = this.selectedDB, disableAnnouncementMessages) {
      const db_index = this.ld.findIndex(this.databases, (database) => {
        return database === db
      })
      this.databases.splice(db_index, 1)
      let successMessage
      let failureMessage
      if (!disableAnnouncementMessages) {
        successMessage = `Database [${db}] deleted!`
        failureMessage = `Failed deleting database [${db}]!`
      }
      RequestsUtils.sendRequest('DELETE', `db/${db}/`, null, successMessage, failureMessage)
      if (!this.databases.includes(this.selectedDB)) {
        this.loadFirstDB()
      }
    },

    async addNewDB(new_db, data) {
      if (!new_db) {
        new_db = Utils.generateUniqueEntityName('new database', this.databases)
      }
      await this.saveDB(new_db, data).then(() => {
        this.loadDB(new_db)
        this.databases.unshift(new_db)
      })
    },

    forkDB() {
      const new_db = Utils.generateUniqueEntityName(this.selectedDB, this.databases, true)
      this.addNewDB(new_db, this.selectedDBData)
    },

    downloadDB(event) {
      let element = event.target
      while (element.nodeName !== 'A')
        element = element.parentNode

      let dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(this.selectedDBData))
      element.setAttribute('href', dataStr)
      element.setAttribute('download', this.selectedDB + '.json')
    },

    initDBKeys() {
      this.keys = Object.keys(this.selectedDBData)
      this.loadKey(this.keys[0])
    },

    loadKey(key) {
      this.selectedKey = key
      this.keyNameInput = this.selectedKey
      this.document = JSON.stringify(this.selectedDBData[key], null, 2)
      this.loadGitLog()
    },

    saveKey(db = this.selectedDB, key = this.selectedKey, doc = this.document) {
      const parsedDoc = JSON.parse(doc)

      return RequestsUtils.sendRequest('PUT', `db/${db}/k/${key}/`, parsedDoc, `Key [${key}] in database [${db}] saved!`, `Failed saving key [${key}] in database [${db}]!`)
    },

    switchKey() {
      this.loadKey(this.selectedKey)
    },

    deleteKey(key, disableAnnouncementMessages) {
      const db = this.selectedDB
      if (!key) {
        key = this.selectedKey
      }
      const key_index = this.ld.findIndex(this.keys, (k) => {
        return k === key
      })
      this.keys.splice(key_index, 1)
      let successMessage
      let failureMessage
      if (!disableAnnouncementMessages) {
        successMessage = `Key [${key}] in database [${db}] deleted!`
        failureMessage = `Failed deleting key [${key}] in database [${db}]!`
      }
      RequestsUtils.sendRequest('DELETE', `db/${db}/k/${key}/`, null, successMessage, failureMessage)
      if (!this.keys.includes(this.selectedKey)) {
        this.loadKey(this.keys[0])
      }
    },

    async addNewKey(new_key, new_document) {
      if (!new_key) {
        new_key = Utils.generateUniqueEntityName('new key', this.keys)
      }
      if (!new_document) {
        new_document = '{}'
      }
      return this.saveKey(this.selectedDB, new_key, new_document).then(() => {
        this.selectedDBData[new_key] = JSON.parse(new_document)
        this.loadKey(new_key)
        this.keys.unshift(new_key)
      })
    },

    forkKey() {
      const new_key = Utils.generateUniqueEntityName(this.selectedKey, this.keys, true)
      const new_document = this.ld.cloneDeep(this.document)
      this.addNewKey(new_key, new_document)
    },

    downloadKey(event) {
      let element = event.target
      while (element.nodeName !== 'A')
        element = element.parentNode

      let dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(this.document)
      element.setAttribute('href', dataStr)
      element.setAttribute('download', this.selectedKey + '.json')
    },

    async saveChanges() {
      // If DB name changed -> Save the data under the new name and remove the old database
      if (this.selectedDB !== this.dbNameInput) {
        const old_db = this.selectedDB
        const old_data_response = await RequestsUtils.sendRequest('GET', `db/${old_db}/`)
        const old_data = old_data_response.data
        await this.addNewDB(this.dbNameInput, old_data)
        this.deleteDB(old_db, true)
      }
      // If key name changed -> Save the data under the new name and remove the old key from the database
      if (this.selectedKey !== this.keyNameInput) {
        const old_key = this.selectedKey
        await this.addNewKey(this.keyNameInput, this.document)
        this.deleteKey(old_key, true)
      } else {
        await this.saveKey(this.selectedDB, this.selectedKey, this.document)
        this.selectedDBData[this.selectedKey] = JSON.parse(this.document)
      }
      await this.loadGitLog()
    },

    async loadGitLog() {
      const url_trail = `db/${this.selectedDB}/k/${this.selectedKey}/v/`
      const response = await RequestsUtils.sendRequest('GET', url_trail)
      this.gitLog = response.data
    },

    async restoreGitVersion(gitVersion) {
      const db = this.selectedDB
      const selectedKey = this.selectedKey
      const version_id = gitVersion.version
      const url_trail = `${db}/v/${version_id}/`

      await RequestsUtils.sendRequest('PUT', `db/${url_trail}revert/`, null, `Database [${db}] restored to version [${version_id}]!`, `Failed restoring database [${db}] to version [${version_id}]!`)
      await this.loadDB(db)
      const oldSelectedKey = this.keys.find((key) => {
        return key === selectedKey
      })
      if (oldSelectedKey) {
        this.loadKey(oldSelectedKey)
      }
      this.loadGitLog()
    },
  },

  created() {
    this.loadDBs()
  }

}

</script>
