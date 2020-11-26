<template>
  <div class="card">
    <div class="card-content">
      <div class="content">
        <div v-for="(section, id) in localSections" :key="id">
          <div class="card">
            <div class="card-content">
              <div class="content">
                <table class="table is-narrow is-fullwidth new-entry-table"
                       v-if="newEntrySectionIndex === id && editable">
                  <thead>
                  <tr>
                    <th class="is-size-7">Category</th>
                    <th class="is-size-7">Entry</th>
                    <th class="is-size-7 is-48-px">
                      <a class="is-small has-text-grey" title="cancel" @click="clearNewEntryData">cancel</a>
                    </th>
                  </tr>
                  </thead>
                  <tbody>
                  <tr>
                    <td class="is-size-7">
                      <div class="select is-small is-fullwidth">
                        <select v-model="newEntryCategory" class="select new-entry-type-selection">
                          <option v-for="(entryType, category) in listEntryTypes" :key="category" :value="category">
                            {{ entryType.title }}
                          </option>
                        </select>
                      </div>
                    </td>
                    <td class="is-size-7">
                          <textarea rows="3"
                                    class="textarea is-small is-fullwidth new-entry-textarea"
                                    :placeholder="inputDescription"
                                    v-model="newEntryItems"></textarea>
                    </td>
                    <td class="is-size-7 is-48-px">
                      <a class="is-small has-text-grey confirm-add-entry-button" title="add entry"
                         @click="addEntry(section, id)">add</a>
                    </td>
                  </tr>
                  </tbody>
                </table>
                <hr v-if="newEntrySectionIndex === id && editable"/>
                <table class="table is-narrow entries-table">
                  <thead>
                  <tr>
                    <th class="is-size-7 is-vcentered is-80-px">
                      <div class="control is-expanded">
                        <div class="select is-small is-size-7">
                          <select v-model="section.relation"
                                  class="relation-selection">
                            <option value="AND">AND</option>
                            <option value="OR">OR</option>
                          </select>
                        </div>
                      </div>
                    </th>
                    <th class="is-size-7 is-vcentered">Category</th>
                    <th class="is-size-7 is-vcentered">Entry</th>
                    <th class="is-size-7 is-vcentered">Annotation</th>
                    <th class=" is-size-7 is-vcentered is-48-px">
                      <a v-if="editable"
                         class="has-text-grey-dark is-small is-pulled-right add-entry-button" title="Add new entry"
                         @click="clearNewEntryData(); newEntrySectionIndex = id">
                        <span class="icon is-small"><i class="fas fa-plus"></i></span>
                      </a>
                    </th>
                  </tr>
                  </thead>
                  <tbody>
                  <tr v-for="(entry,idx) in selectedSectionPage[id]" :key="idx" class="entry-row">
                    <td class="is-size-7 is-80-px has-text-centered has-text-grey-light entry-number">
                      {{ ((idx + 1) + ((currentSectionPage[id] - 1) * rowsPerPage)) }}
                    </td>
                    <td class="is-size-7 entry-category">{{ listEntryTypes[entry[0]].title }}</td>
                    <td class="is-size-7 entry-value"><span v-html="dualCell(entry[1])"></span></td>
                    <td class="is-size-7 entry-annotation" :title="entry[2]">{{
                        entry[2] ? entry[2].substr(0, 40) : ''
                      }}
                    </td>
                    <td class="is-size-7 is-48-px">
                      <a v-if="editable"
                         class="is-small has-text-grey remove-entry-button" title="remove entry"
                         @click="removeEntry(section, id, idx)">
                        remove
                      </a>
                    </td>
                  </tr>
                  <tr v-if="totalPages(section) > 1">
                    <td colspan="5">
                      <nav class="pagination is-small" role="navigation" aria-label="pagination">
                        <a :disabled="currentSectionPage[id] === 1" class="is-pulled-left pagination-previous"
                           @click="navigate(section, id, currentSectionPage[id] - 1)">Previous Page</a>
                        <a :disabled="currentSectionPage[id] === totalPages(section)"
                           class="is-pulled-right pagination-next"
                           @click="navigate(section, id, currentSectionPage[id] + 1)">Next page</a>
                      </nav>
                    </td>
                  </tr>
                  </tbody>
                </table>
                <button v-if="editable"
                        class="button has-text-danger remove-entries-block-button"
                        title="Delete this entries block"
                        @click="removeEntryBlock(id)">
                  Remove entries block
                </button>
              </div>
            </div>
          </div>
          <div class="control is-expanded relation-selection-wrapper"
               v-if="localSections.length > 1 && id !== localSections.length - 1">
            <div class="select is-small is-size-7">
              <select v-model="rule.relation"
                      class="relation-selection">
                <option value="AND">AND</option>
                <option value="OR">OR</option>
              </select>
            </div>
          </div>
        </div>
        <button v-if="editable"
                class="button add-entries-block-button"
                title="Add new entries block"
                @click="addEntryBlock">
          Add new entries block
        </button>
      </div>
    </div>
  </div>

</template>

<script>
import Vue from 'vue'

export default {
  name: 'EntriesRelationList',

  props: {
    rule: {
      type: Object,
      default: () => {
        return {
          relation: 'OR',
          sections: []
        }
      },
      validator(value) {
        if (!value || !value.relation || !value.sections) {
          return false
        }
        const isRelationValid = ['OR', 'AND'].includes(value.relation.toUpperCase())
        const isListInvalid = value.sections.find((section) => {
          const isSectionRelationInvalid = !(['OR', 'AND'].includes(value.relation.toUpperCase()))
          const isSectionsEntriesInvalid = !section.entries || section.entries.find((entry) => {
            return (!entry || !entry.length || entry.length < 2 || entry.length > 3)
          })
          return isSectionRelationInvalid || isSectionsEntriesInvalid
        })
        return isRelationValid && !isListInvalid
      }
    },
    editable: Boolean,
  },

  data() {
    return {
      rowsPerPage: 20,
      currentSectionPage: [],
      selectedSectionPage: [],
      listEntryTypes: {
        'path': {'title': 'Path', 'pair': false},
        'query': {'title': 'Query', 'pair': false},
        'uri': {'title': 'URI', 'pair': false},
        'method': {'title': 'Method', 'pair': false},
        'ip': {'title': 'IP Address', 'pair': false},
        'asn': {'title': 'ASN', 'pair': false},
        'country': {'title': 'Country', 'pair': false},
        'headers': {'title': 'Headers', 'pair': true},
        'args': {'title': 'Arguments', 'pair': true},
        'cookies': {'title': 'Cookies', 'pair': true},
      },
      newEntrySectionIndex: -1,
      // newEntryCategory - start with most common category - IP
      newEntryCategory: 'ip',
      newEntryItems: '',
      localSections: []
    }
  },

  computed: {
    inputDescription() {
      if ((new RegExp('(args|cookies|headers)')).test(this.newEntryCategory)) {
        return '1st line: NAME\n2nd line: VALUE\n3rd line: optional annotation'
      }
      return 'One entry per line, use \'#\' for annotation\ne.g. 12.13.14.15 #San Jose Office'
    },
  },

  watch: {
    rule: {
      handler: function (newVal) {
        this.localSections = newVal.sections
        for (let i = 0; i < this.localSections.length; i++) {
          this.currentSectionPage[i] = 1
          this.loadSelectedPageData(this.localSections[i], i)
        }
      },
      immediate: true,
      deep: true
    }
  },

  methods: {
    clearNewEntryData() {
      this.newEntryItems = ''
      this.newEntryCategory = 'ip'
      this.newEntrySectionIndex = -1
    },

    totalPages(section) {
      return Math.ceil(this.sectionTotalEntries(section) / this.rowsPerPage)
    },

    sectionTotalEntries(section) {
      return section?.entries?.length || 0
    },

    loadSelectedPageData(section, sectionIndex) {
      let entries = []
      if (this.sectionTotalEntries(section) !== 0) {
        entries = section.entries
        entries = this.ld.slice(entries, (this.currentSectionPage[sectionIndex] - 1) * this.rowsPerPage, this.rowsPerPage * this.currentSectionPage[sectionIndex])
      }
      Vue.set(this.selectedSectionPage, sectionIndex, entries)
    },

    dualCell(cell) {
      if (this.ld.isArray(cell)) {
        return `name: ${cell[0]}<br/>value: ${cell[1]}`
      } else {
        return cell
      }
    },

    navigate(section, sectionIndex, pageNum) {
      if (pageNum >= 1 && pageNum <= this.totalPages(section)) {
        this.currentSectionPage[sectionIndex] = pageNum
        this.loadSelectedPageData(section, sectionIndex)
      }
    },

    addEntryBlock() {
      const newSection = {
        relation: 'OR',
        entries: []
      }
      this.localSections.push(newSection)
      this.currentSectionPage[this.localSections.length - 1] = 1
      this.loadSelectedPageData(newSection, 1)
    },

    removeEntryBlock(sectionIndex) {
      this.localSections.splice(sectionIndex, 1)
      this.currentSectionPage.splice(sectionIndex, 1)
      this.selectedSectionPage.splice(sectionIndex, 1)
      if (this.newEntrySectionIndex === sectionIndex) {
        this.clearNewEntryData()
      }
    },

    addEntry(section, sectionIndex) {
      // dual cell
      if ((new RegExp('(args|cookies|headers)')).test(this.newEntryCategory)) {
        let entries = this.newEntryItems.trim().split('\n')
        if (entries.length === 3 || entries.length === 2) {
          section.entries.unshift([this.newEntryCategory, [entries[0].trim(), entries[1].trim()], entries[2].trim()])
        }
      }
      // single line entry
      else {
        this.ld.each(this.newEntryItems.split('\n'), (line) => {
          let [entry, annotation] = line.trim().split('#')
          annotation = annotation && annotation.trim()
          section.entries.unshift([this.newEntryCategory, entry.trim(), annotation])
        })
      }
      this.clearNewEntryData()
      this.loadSelectedPageData(section, sectionIndex)
    },

    removeEntry(section, sectionIndex, idx) {
      let pointer = ((this.currentSectionPage[sectionIndex] - 1) * this.rowsPerPage) + idx
      section.entries.splice(pointer, 1)
      this.loadSelectedPageData(section, sectionIndex)
    },
  }
}
</script>
<style scoped>
.entries-table {
  margin-bottom: 2rem;
}

.is-48-px {
  min-width: 48px;
  max-width: 48px;
  width: 48px;
}

.is-80-px {
  min-width: 80px;
  max-width: 80px;
  width: 80px;
}

.relation-selection-wrapper {
  text-align: center;
  margin-bottom: 2rem;
}

.relation-selection-wrapper:before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  border-top: 1px solid black;
  background: black;
  width: 100%;
  transform: translateY(-50%);
}
</style>
