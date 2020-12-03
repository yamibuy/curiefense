<template>
  <div class="card">
    <div class="card-content">
      <div class="content">
        <div class="columns">
          <div class="column is-6" style="border-right:solid 2px #f8f8f8; ">
            <div class="field">
              <label class="label is-small">
                Name
                <span class="has-text-grey is-pulled-right" title="Flow control id">
                    {{ selectedDoc.id }}
                  </span>
              </label>
              <div class="control">
                <input class="input is-small"
                       placeholder="Flow control name"
                       v-model="selectedDoc.name"/>
              </div>
            </div>
            <div class="field">
              <label class="label is-small has-text-left form-label">TTL</label>
              <div class="control">
                <input class="input is-small" type="text" placeholder="New rate limit rule name" v-model="selectedDoc.ttl">
              </div>
            </div>
            <div class="field">
              <label class="label is-small has-text-left form-label">Count by</label>
              <div class="group-key">
                <limit-option
                    v-for="(option, idx) in selectedDoc.key"
                    show-remove
                    @remove="removeKey(idx)"
                    @change="updateKeyOption"
                    :removable="selectedDoc.key.length > 1"
                    :index="idx"
                    :option="generateOption(option)"
                    :key="getOptionTextKey(option, idx)"/>
                <a title="Add new option rule"
                   class="is-text is-small is-size-7 ml-4"
                   @click="addKey()">
                  New entry
                </a>
                <br>
                <p class="has-text-danger pl-3 mt-3 is-size-7" v-if="!keysAreValid">
                  Count-by entries must be unique
                </p>
              </div>
            </div>
            <div class="field">
              <limit-action :action.sync="selectedDoc.action"/>
            </div>
            <div class="columns">
              <div class="column is-6 filter-column" v-for="filter in filters" :key="filter">
                <p class="title is-7 is-uppercase">{{ titles[filter] }}</p>
                <hr :style="barStyle[filter]"/>
                <table class="table is-narrow is-fullwidth">
                  <tbody>
                  <tr v-for="(tag, tagIndex) in selectedDoc[filter]" :key="tagIndex">
                    <td class="tag-cell"
                        :class=" duplicateTags[tag] ? 'has-text-danger' : '' ">
                      {{ tag }}
                    </td>
                    <td class="is-size-7 is-18-px">
                      <a title="remove entry"
                         class="is-small has-text-grey remove-entry-button"
                         @click="removeTag(filter, tagIndex)">
                        &ndash;
                      </a>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <tag-autocomplete-input v-if="addNewTagColName === filter"
                                              ref="tagAutocompleteInput"
                                              :clearInputAfterSelection="true"
                                              :selectionType="'single'"
                                              :autoFocus="true"
                                              @keydown.esc="cancelAddNewTag"
                                              @tagSubmitted="addNewTag(filter, $event)">
                      </tag-autocomplete-input>
                    </td>
                    <td class="is-size-7 is-18-px">
                      <a title="add new entry"
                         class="is-size-7 is-18-px is-small has-text-grey add-new-entry-button"
                         @click="openTagInput(filter)">
                        +
                      </a>
                    </td>
                  </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div class="column is-6">
            <div class="sequence-wrapper">
              <div v-for="(sequenceItem, sequenceIndex) in localDoc.sequence"
                   :key="sequenceIndex"
                   class="sequence">
                <div class="sequence-entries">
                  <table class="table is-narrow is-size-7 sequence-entry">
                    <tbody>
                    <tr>
                      <td class="is-size-7 is-48-px sequence-entries-relation"></td>
                      <td class="is-120-px">
                        Method
                      </td>
                      <td>
                        <input class="input is-small" v-model="sequenceItem.method" @input="emitDocUpdate"/>
                      </td>
                      <td class="is-80-px"></td>
                    </tr>
                    <tr>
                      <td class="is-size-7 is-48-px has-text-centered has-text-grey-light has-text-weight-medium sequence-entries-relation">
                        AND
                      </td>
                      <td class="is-120-px">
                        URI
                      </td>
                      <td>
                        <input class="input is-small" v-model="sequenceItem.uri" @input="emitDocUpdate"/>
                      </td>
                      <td class="is-80-px"></td>
                    </tr>
                    <tr v-for="(sequenceEntry, sequenceEntryIndex) in sequenceItemEntries(sequenceIndex)"
                        :key="sequenceEntryIndex">
                      <td class="is-size-7 is-48-px has-text-centered has-text-grey-light has-text-weight-medium sequence-entries-relation">
                        AND
                      </td>
                      <td class="is-120-px">
                        {{ listEntryTypes[sequenceEntry[0]].title }}
                      </td>
                      <td>
                        <span v-html="dualCell(sequenceEntry[1])"></span>
                      </td>
                      <td class="is-80-px">
                        <a class="is-small has-text-grey"
                           title="Remove sequence entry"
                           @click="removeSequenceItemEntry(sequenceIndex, sequenceEntry[0], sequenceEntry[1][0])">
                          remove
                        </a>
                      </td>
                    </tr>
                    <tr v-if="newEntrySectionIndex !== sequenceIndex">
                      <td>
                        <a class="is-size-7 light add" title="add new row"
                           @click="setNewEntryIndex(sequenceIndex)"><i class="fas fa-plus"></i></a>
                        &nbsp;&middot;&nbsp;
                        <a class="is-size-7 light remove" title="remove entire section"
                           @click="removeSequenceItem(sequenceIndex)"><i class="fas fa-trash"></i></a>
                      </td>
                      <td colspan="4">
                      </td>
                    </tr>
                    <tr v-if="newEntrySectionIndex === sequenceIndex" class="new-entry-row">
                      <td></td>
                      <td class="is-size-7">
                        <div class="select is-small is-fullwidth">
                          <select v-model="newEntryType" class="select new-entry-type-selection">
                            <option v-for="(entryType, category) in listEntryTypes" :key="category" :value="category">
                              {{ entryType.title }}
                            </option>
                          </select>
                        </div>
                      </td>
                      <td class="is-size-7">
                      <textarea v-model="newEntryItems"
                                :placeholder="inputDescription"
                                class="textarea is-small is-fullwidth new-entry-textarea"
                                rows="3">
                      </textarea>
                      </td>
                      <td class="is-size-7 is-80-px">
                        <a class="is-size-7 x-has-text-grey grey add" title="add new row"
                           @click="addSequenceItemEntry(sequenceIndex)"><i class="fas fa-check"></i> Add</a>
                        <br/>
                        <a class="is-size-7 x-has-text-grey grey remove" title="add new row"
                           @click="setNewEntryIndex(-1)"><i class="fas fa-times"></i> Cancel</a>
                      </td>
                    </tr>
                    </tbody>
                  </table>
                </div>
                <div v-if="localDoc.sequence.length > 1 && sequenceIndex !== localDoc.sequence.length - 1"
                     class="control is-expanded relation-wrapper">
              <span class="tag is-small is-relative">
                THEN
              </span>
                </div>
              </div>
              <button class="button is-small new-sequence-button"
                      @click="addSequenceItem()">
                Create new sequence section
              </button>
            </div>
          </div>
        </div>
        <span class="is-family-monospace has-text-grey-lighter">{{ apiPath }}</span>
      </div>
    </div>
  </div>
</template>

<script>

import LimitAction from '@/components/LimitAction'
import LimitOption from '@/components/LimitOption'
import TagAutocompleteInput from '@/components/TagAutocompleteInput'
import DatasetsUtils from '@/assets/DatasetsUtils'

export default {
  name: 'FlowControl',

  props: {
    selectedDoc: Object,
    apiPath: String
  },

  components: {
    LimitAction,
    LimitOption,
    TagAutocompleteInput
  },

  data() {
    return {
      filters: ["include", "exclude"],
      barStyle: {
        "include": "background-color: hsl(141,  71%, 48%); margin: 1rem 0 0.5rem 0;",
        "exclude": "background-color: hsl(348, 100%, 61%); margin: 1rem 0 0.5rem 0;",
      },
      addNewTagColName: null,
      titles: DatasetsUtils.Titles,
      defaultSequenceItemEntry: ['cookies', ''],
      defaultSequenceItem: {
        'method': 'GET',
        'uri': '/login',
        'cookies': {},
        'headers': {},
        'args': {}
      },
      listEntryTypes: {
        'headers': {'title': 'Header', 'pair': true},
        'args': {'title': 'Argument', 'pair': true},
        'cookies': {'title': 'Cookie', 'pair': true},
      },
      keysAreValid: true,
      newEntrySectionIndex: -1,
      newEntryType: 'args',
      newEntryItems: ''
    }
  },

  computed: {
    localDoc() {
      return JSON.parse(JSON.stringify(this.selectedDoc))
    },

    inputDescription() {
      return '1st line: NAME\n2nd line: VALUE\n3rd line: optional annotation'
    },

    duplicateTags() {
      let doc = this.selectedDoc;
      let allTags = this.ld.concat(doc["include"], doc["exclude"]);
      let dupTags = this.ld.filter(allTags, (val, i, iteratee) => this.ld.includes(iteratee, val, i + 1));
      return this.ld.fromPairs(this.ld.zip(dupTags, dupTags))
    },
  },

  methods: {
    emitDocUpdate() {
      this.$emit('update', this.localDoc)
    },

    dualCell(cell) {
      if (this.ld.isArray(cell)) {
        return `${cell[0]}: ${cell[1]}`
      } else {
        return cell
      }
    },

    // Key

    getOptionTextKey(option, idx) {
      const [type] = Object.keys(option)
      return `${this.selectedDoc.id}_${type}_${idx}`
    },

    generateOption(data, optionType = null) {
      if (!data) {
        return {}
      }
      const [firstObjectKey] = Object.keys(data)
      const type = optionType ? optionType : firstObjectKey
      const key = optionType ? firstObjectKey : (data[firstObjectKey] || null)
      const value = optionType ? data[firstObjectKey] : null
      return {type, key, value}
    },

    addKey() {
      this.selectedDoc.key.push({attrs: 'ip'})
      this.checkKeysValidity()
    },

    removeKey(idx) {
      if (this.selectedDoc.key.length > 1) {
        this.selectedDoc.key.splice(idx, 1)
      }
      this.checkKeysValidity()
    },

    updateKeyOption(option, index = 0) {
      this.selectedDoc.key.splice(index, 1, {
        [option.type]: option.key
      })
      this.checkKeysValidity()
    },

    checkKeysValidity() {
      const keysToCheck = this.ld.countBy(this.selectedDoc.key, item => {
        const key = Object.keys(item)[0]
        return `${key}_${item[key]}`
      })
      this.keysAreValid = true
      for (const key of Object.keys(keysToCheck)) {
        if (keysToCheck[key] > 1) {
          this.keysAreValid = false
          break
        }
      }
      return this.keysAreValid
    },

    // Sequence

    setNewEntryIndex(index) {
      this.newEntryItems = ''
      this.newEntryType = 'args'
      this.newEntrySectionIndex = index
    },

    sequenceItemEntries(sequenceIndex) {
      const sequenceItem = this.localDoc.sequence[sequenceIndex]
      const cookiesEntries = Object.entries(sequenceItem.cookies)
      const headersEntries = Object.entries(sequenceItem.headers)
      const argsEntries = Object.entries(sequenceItem.args)
      const mergedEntries = []
      for (let i = 0; i < cookiesEntries.length; i++) {
        mergedEntries.push(['cookies', cookiesEntries[i]])
      }
      for (let i = 0; i < headersEntries.length; i++) {
        mergedEntries.push(['headers', headersEntries[i]])
      }
      for (let i = 0; i < argsEntries.length; i++) {
        mergedEntries.push(['args', argsEntries[i]])
      }
      return mergedEntries
    },

    addSequenceItem() {
      this.localDoc.sequence.push(this.defaultSequenceItem)
      this.emitDocUpdate()
    },

    removeSequenceItem(sequenceIndex) {
      this.localDoc.sequence.splice(sequenceIndex, 1)
      this.emitDocUpdate()
    },

    addSequenceItemEntry(sequenceIndex) {
      const sequenceItem = this.localDoc.sequence[sequenceIndex]
      let entries = this.newEntryItems.trim().split('\n')
      if (entries.length > 1) {
        let a = entries[0].trim(),
            b = entries[1].trim(),
            annotation = entries.length === 3 ? `#${entries[2].trim()}` : ''

        if (!Object.prototype.hasOwnProperty.call(sequenceItem[this.newEntryType], a)) {
          sequenceItem[this.newEntryType][a] = b + annotation
        }
      }
      this.setNewEntryIndex(-1)
      this.emitDocUpdate()
    },

    changeEntryType(sequenceIndex, type, entry, newType) {
      const sequenceItem = this.localDoc.sequence[sequenceIndex]
      delete sequenceItem[type][entry[0]]
      sequenceItem[newType][entry[0]] = entry[1]
      this.emitDocUpdate()
    },

    updateSequenceItemEntry(sequenceIndex, type, key, value) {
      const sequenceItem = this.localDoc.sequence[sequenceIndex]
      sequenceItem[type][key] = value
      this.emitDocUpdate()
    },

    removeSequenceItemEntry(sequenceIndex, type, key) {
      const sequenceItem = this.localDoc.sequence[sequenceIndex]
      delete sequenceItem[type][key]
      this.emitDocUpdate()
    },

    // Tags filters

    addNewTag(section, entry) {
      if (entry && entry.length > 2) {
        this.selectedDoc[section].push(entry)
        this.emitDocUpdate()
      }
    },

    openTagInput(section) {
      this.addNewTagColName = section
    },

    cancelAddNewTag() {
      this.addNewTagColName = null
    },

    removeTag(section, idx) {
      this.selectedDoc[section].splice(idx, 1)
      this.addNewTagColName = null
      this.emitDocUpdate()
    }
  },
}
</script>

<style scoped>

.sequence-entries {
  margin-bottom: 0.75rem
}

.sequence-entries-relation {
  margin-bottom: 1rem
}

.sequence-entry .select, .sequence-entry select {
  width: 100%
}

.relation-wrapper {
  text-align: center;
  margin-bottom: 1rem;
}

.relation-wrapper:before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  border-top: 1px solid black;
  background: black;
  width: 100%;
  transform: translateY(-50%);
}

.filter-column:first-of-type {
  padding-left: 0
}

.filter-column:last-of-type {
  padding-right: 0
}

/deep/ .limit-actions {
  padding: 0
}

/deep/ .tag-input {
  font-size: 0.58rem
}

.light {
  color: hsl(0, 0%, 86%)
}

.add:hover {
  color: hsl(0, 0%, 21%)
}

.remove:hover {
  color: hsl(348, 100%, 61%)
}

.is-18-px {
  min-width: 18px;
  max-width: 18px;
  width: 18px;
}

.is-48-px {
  min-width: 40px;
  max-width: 40px;
  width: 48px;
}

.is-80-px {
  min-width: 80px;
  max-width: 80px;
  width: 80px;
}

.is-120-px {
  min-width: 120px;
  max-width: 120px;
  width: 120px;
}

</style>
