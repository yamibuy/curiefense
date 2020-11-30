<template>
  <div>
    <div class="columns has-text-black-bis rule-bar">
        <div class="column is-height-30-px">
          <div class="field is-grouped">
            <div class="control">
              <span class="is-size-7">Sections: {{ localRule.sections.length }}</span>
            </div>
            <div class="control">
              <span class="is-size-7">
                Sections relation:
                <span class="tag is-small is-info is-light rule-relation-toggle"
                      @click="toggleRuleRelation()">
                  {{ localRule.relation }}
                </span>
              </span>
            </div>
          </div>
        </div>
        <div class="column is-height-30-px">
          <div v-if="editable"
               class="field is-grouped is-pulled-right">
            <div class="control">
              <button class="button is-small has-text-primary-dark add-section-button"
                      title="Add new section"
                      @click="addSection">
                Add new
              </button>
            </div>
            <div class="control">
              <button class="button is-small has-text-danger-dark remove-all-sections-button"
                      title="Remove all sections"
                      @click="removeAllSections">
                Remove all
              </button>
            </div>
          </div>
        </div>
      </div>
    <hr/>
    <div class="sections-wrapper">
      <div v-for="(section, id) in localRule.sections" :key="id" class="section">
        <div class="card">
          <div class="card-content">
            <div class="content">
              <div class="columns has-text-grey section-bar">
                <div class="column is-height-30-px">
                  <div class="field is-grouped">
                    <div class="control">
                      <span class="is-size-7">Entries: {{ section.entries.length }}</span>
                    </div>
                    <div class="control">
                  <span class="is-size-7">
                    Entries relation:
                    <span class="tag is-small is-info is-light section-relation-toggle"
                          @click="toggleSectionRelation(section)">
                      {{ section.relation }}
                    </span>
                  </span>
                    </div>
                  </div>
                </div>
                <div class="column is-height-30-px">
                  <div v-if="editable"
                       class="field is-grouped is-pulled-right">
                    <div class="control">
                      <button class="button is-small has-text-primary add-entry-button"
                              title="Add new entry"
                              @click="clearNewEntryData(); newEntrySectionIndex = id">
                        Add entry
                      </button>
                    </div>
                    <div class="control">
                      <button class="button is-small has-text-danger remove-section-button"
                              title="Remove section"
                              @click="removeSection(id)">
                        Remove section
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <hr/>
              <table v-if="newEntrySectionIndex === id && editable"
                     class="table is-narrow is-fullwidth new-entry-table">
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
                          <textarea v-model="newEntryItems"
                                    :placeholder="inputDescription"
                                    class="textarea is-small is-fullwidth new-entry-textarea"
                                    rows="3"></textarea>
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
                  <th class="is-size-7 is-vcentered is-48-px"></th>
                  <th class="is-size-7 is-vcentered">Category</th>
                  <th class="is-size-7 is-vcentered">Entry</th>
                  <th class="is-size-7 is-vcentered">Annotation</th>
                  <th class=" is-size-7 is-vcentered is-48-px"></th>
                </tr>
                </thead>
                <tbody>
                <tr v-for="(entry,idx) in sectionsCurrentPage[id]" :key="idx" class="entry-row">
                  <td class="is-size-7 is-48-px has-text-centered has-text-grey-light entry-number">
                  <span v-if="((idx + 1) + ((sectionsCurrentPageIndex[id] - 1) * rowsPerPage)) !== 1"
                        class="tag is-small is-info is-light section-relation-toggle"
                        @click="toggleSectionRelation(section)">
                    {{ section.relation }}
                  </span>
                  </td>
                  <td class="is-size-7 entry-category">{{ listEntryTypes[entry[0]].title }}</td>
                  <td class="is-size-7 entry-value"><span v-html="dualCell(entry[1])"></span></td>
                  <td :title="entry[2]" class="is-size-7 entry-annotation">{{
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
                    <nav aria-label="pagination" class="pagination is-small" role="navigation">
                      <a :disabled="sectionsCurrentPageIndex[id] === 1" class="is-pulled-left pagination-previous"
                         @click="navigate(section, id, sectionsCurrentPageIndex[id] - 1)">Previous Page</a>
                      <a :disabled="sectionsCurrentPageIndex[id] === totalPages(section)"
                         class="is-pulled-right pagination-next"
                         @click="navigate(section, id, sectionsCurrentPageIndex[id] + 1)">Next page</a>
                    </nav>
                  </td>
                </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <div v-if="localRule.sections.length > 1 && id !== localRule.sections.length - 1"
             class="control is-expanded relation-selection-wrapper">
        <span class="tag is-small is-info is-light is-relative rule-relation-toggle"
              @click="toggleRuleRelation()">
          {{ localRule.relation }}
        </span>
        </div>
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
          const isSectionsEntriesInvalid = !section.entries || !section.entries.find || section.entries.find((entry) => {
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
      sectionsCurrentPageIndex: [],
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
      newEntryItems: ''
    }
  },

  computed: {
    inputDescription() {
      if (this.isCategoryMultiline(this.newEntryCategory)) {
        return '1st line: NAME\n2nd line: VALUE\n3rd line: optional annotation'
      }
      return 'One entry per line, use \'#\' for annotation\ne.g. 12.13.14.15 #San Jose Office'
    },

    sectionsCurrentPage() {
      let pages = []
      for (let i = 0; i < this.localRule.sections.length; i++) {
        const section = this.localRule.sections[i]
        if (this.sectionTotalEntries(section) !== 0) {
          pages[i] = section.entries
          pages[i] = this.ld.slice(pages[i], (this.sectionsCurrentPageIndex[i] - 1) * this.rowsPerPage, this.rowsPerPage * this.sectionsCurrentPageIndex[i])
        }
      }
      return pages
    },

    localRule() {
      return JSON.parse(JSON.stringify(this.rule))
    },
  },

  watch: {
    rule: {
      handler: function () {
        for (let i = 0; i < this.localRule.sections.length; i++) {
          const section = this.localRule.sections[i]
          Vue.set(this.sectionsCurrentPageIndex, i, 1)
          if (this.sectionContainsSameCategoryItems(section)) {
            section.relation = 'OR'
          }
        }
      },
      immediate: true,
      deep: true
    }
  },

  methods: {
    isCategoryMultiline(category) {
      return (new RegExp('(args|cookies|headers)')).test(category)
    },

    emitRuleUpdate() {
      this.$emit('update', this.localRule)
    },

    sectionContainsSameCategoryItems(section) {
      const countedCategories = this.ld.countBy(section.entries, (entry) => {
        return this.listEntryTypes[entry[0]].title
      })
      const categoriesKeys = Object.keys(this.listEntryTypes)
      for (let i = 0; i < categoriesKeys.length; i++) {
        const categoryKey = categoriesKeys[i]
        const category = this.listEntryTypes[categoryKey]
        if (this.isCategoryMultiline(categoryKey)) {
          break
        }
        if (countedCategories[category.title] > 1) {
          return true
        }
      }
      return false
    },

    toggleRuleRelation() {
      if (this.localRule.relation === 'AND') {
        this.localRule.relation = 'OR'
      } else {
        this.localRule.relation = 'AND'
      }
      this.emitRuleUpdate()
    },

    toggleSectionRelation(section) {
      if (this.sectionContainsSameCategoryItems(section)) {
        return
      }
      if (section.relation === 'AND') {
        section.relation = 'OR'
      } else {
        section.relation = 'AND'
      }
      this.emitRuleUpdate()
    },

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

    dualCell(cell) {
      if (this.ld.isArray(cell)) {
        return `name: ${cell[0]}<br/>value: ${cell[1]}`
      } else {
        return cell
      }
    },

    navigate(section, sectionIndex, pageNum) {
      if (pageNum >= 1 && pageNum <= this.totalPages(section)) {
        Vue.set(this.sectionsCurrentPageIndex, sectionIndex, pageNum)
      }
    },

    addSection() {
      const newSection = {
        relation: 'OR',
        entries: []
      }
      this.localRule.sections.push(newSection)
      Vue.set(this.sectionsCurrentPageIndex, this.localRule.sections.length - 1, 1)
      this.emitRuleUpdate()
    },

    removeAllSections() {
      this.localRule.sections.splice(0, this.localRule.sections.length)
      this.sectionsCurrentPageIndex.splice(0, this.sectionsCurrentPageIndex.length)
      this.clearNewEntryData()
      this.emitRuleUpdate()
    },

    removeSection(sectionIndex) {
      this.localRule.sections.splice(sectionIndex, 1)
      this.sectionsCurrentPageIndex.splice(sectionIndex, 1)
      if (this.newEntrySectionIndex === sectionIndex) {
        this.clearNewEntryData()
      }
      this.emitRuleUpdate()
    },

    addEntry(section) {
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
      if (this.sectionContainsSameCategoryItems(section)) {
        section.relation = 'OR'
      }
      this.clearNewEntryData()
      this.emitRuleUpdate()
    },

    removeEntry(section, sectionIndex, idx) {
      let pointer = ((this.sectionsCurrentPageIndex[sectionIndex] - 1) * this.rowsPerPage) + idx
      section.entries.splice(pointer, 1)
      this.emitRuleUpdate()
    },
  }
}
</script>
<style scoped>
.section {
  padding: initial;
}

.entries-table {
  margin-bottom: 2rem;
}

.is-48-px {
  min-width: 48px;
  max-width: 48px;
  width: 48px;
}

.is-height-30-px {
  min-height: 30px;
  max-height: 30px;
  height: 30px;
  box-sizing: content-box;
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

.sections-wrapper {
  max-height: 1000px;
  overflow-y: auto;
}

.rule-relation-toggle, .section-relation-toggle {
  cursor: pointer
}
</style>
