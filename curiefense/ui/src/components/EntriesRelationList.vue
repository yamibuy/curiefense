<template>
  <div>
    <div class="tile is-ancestor">
      <div class="tile is-vertical">
        <div class="tile">
          <div class="tile is-parent is-vertical">
            <div class="tile is-child box is-primary section"
              v-for="(section, section_idx) in localRule.sections" :key="section_idx">
              <!-- <div v-if="localRule.sections.length > 1 && id > 0"
                   class="control is-expanded relation-selection-wrapper"> -->
                <center v-if="localRule.sections.length > 1 && section_idx > 0">
                  <span class="tag has-text-weight-semibold"
                    style="margin-top: -24px; position: absolute!important"
                  >{{ localRule.relation }}</span>
                </center>
              <!-- </div> -->
              <table class="table is-narrow entries-table">
                <tbody>
                  <tr v-for="(entry,entry_idx) in sectionsCurrentPage[section_idx]" :key="entry_idx" class="entry-row">
                    <td class="is-size-7 is-48-px has-text-centered has-text-weight-medium">
                      <span v-if="((entry_idx + 1) + ((sectionsCurrentPageIndex[section_idx] - 1) * rowsPerPage)) !== 1"
                            class="is-small pointer section-relation-toggle"
                            @click="toggleSectionRelation(section)"
                      >
                        {{ section.relation }}
                      </span>
                    </td>
                    <td class="is-size-7 entry-category has-text-weight-medium">{{ listEntryTypes[entry[0]].title }}</td>
                    <td class="is-size-7 entry-value"><span v-html="dualCell(entry[1])"></span></td>
                    <td :title="entry[2]" class="is-size-7 entry-annotation">
                      {{ entry[2] ? entry[2].substr(0, 60) : '' }}
                    </td>
                    <td class="is-size-7 is-80-px">
                      <a v-if="editable"
                         class="is-small has-text-grey remove-entry-button" title="remove entry"
                         @click="removeEntry(section, section_idx, entry_idx)">
                        remove
                      </a>
                    </td>
                  </tr>
                  <tr v-if="newEntrySectionIndex !== section_idx && editable">
                    <td>
                      <a class="is-size-7 light add add-entry-button" title="add new row" @click="clearNewEntryData(section_idx)"><i class="fas fa-plus"></i></a>
                      &nbsp;&middot;&nbsp;
                      <a class="is-size-7 light remove remove-section-button" title="remove entire section" @click="removeSection(section_idx)"><i class="fas fa-trash"></i></a>
                    </td>
                    <td colspan="4">
                    </td>

                  </tr>
                  <tr v-if="newEntrySectionIndex === section_idx && editable" class="new-entry-row">
                    <td></td>
                    <td class="is-size-7">
                      <div class="select is-small is-fullwidth">
                        <select v-model="newEntryCategory" class="select new-entry-type-selection">
                          <option v-for="(entryType, category) in listEntryTypes" :key="category" :value="category">
                            {{ entryType.title }}
                          </option>
                        </select>
                      </div>
                    </td>
                    <td class="is-size-7" colspan="2">
                      <textarea v-model="newEntryItems"
                                :placeholder="inputDescription"
                                class="textarea is-small is-fullwidth new-entry-textarea"
                                rows="3">
                      </textarea>
                    </td>
                    <td class="is-size-7 is-80-px">
                      <a class="is-size-7 x-has-text-grey grey add confirm-add-entry-button" title="add new row" @click="addEntry(section, section_idx)"><i class="fas fa-check"></i> Add</a>
                      <br/>
                      <a class="is-size-7 x-has-text-grey grey remove" title="cancel add new row" @click="clearNewEntryData(-1)"><i class="fas fa-times"></i> Cancel</a>
                    </td>
                  </tr>

                  <tr v-if="totalPages(section) > 1">
                    <td colspan="5">
                      <nav aria-label="pagination" class="pagination is-small" role="navigation">
                        <a :disabled="sectionsCurrentPageIndex[section_idx] === 1" class="is-pulled-left pagination-previous"
                           @click="navigate(section, section_idx, sectionsCurrentPageIndex[section_idx] - 1)">Previous Page</a>
                        <a :disabled="sectionsCurrentPageIndex[section_idx] === totalPages(section)"
                           class="is-pulled-right pagination-next"
                           @click="navigate(section, section_idx, sectionsCurrentPageIndex[section_idx] + 1)">Next page</a>
                      </nav>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="editable" class="field is-grouped is-pulled-left">
      <div class="control">
        <button class="button is-small x-has-text-grey add-section-button"
                title="Add new section"
                @click="addSection">
          Create new section
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
      // rowsPerPage: 20, >> computed property now
      sectionsCurrentPageIndex: [],
      listEntryTypes: {
        'path': {'title': 'Path', 'pair': false},
        'query': {'title': 'Query', 'pair': false},
        'uri': {'title': 'URI', 'pair': false},
        'method': {'title': 'Method', 'pair': false},
        'ip': {'title': 'IP Address', 'pair': false},
        'asn': {'title': 'ASN', 'pair': false},
        'country': {'title': 'Country', 'pair': false},
        'headers': {'title': 'Header', 'pair': true},
        'args': {'title': 'Argument', 'pair': true},
        'cookies': {'title': 'Cookie', 'pair': true},
      },
      newEntrySectionIndex: -1,
      // newEntryCategory - start with most common category - IP
      newEntryCategory: 'ip',
      newEntryItems: ''
    }
  },

  computed: {

    rowsPerPage() {
      // no pagination for multiple sections
      return this.localRule.sections.length > 1 ? 1000*1000 : 20
    },

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
        this.sectionsCurrentPageIndex = []
        for (let i = 0; i < this.localRule.sections.length; i++) {
          let section = this.localRule.sections[i]
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
        let categoryKey = categoriesKeys[i]
        let category = this.listEntryTypes[categoryKey]
        if (this.isCategoryMultiline(categoryKey)) {
          break
        }
        if (countedCategories[category.title] > 1) {
          return true
        }
      }
      return false
    },

    toggleSectionRelation(section) {
      if (this.sectionContainsSameCategoryItems(section)) {
        return
      }
      section.relation = (section.relation === 'AND') ? "OR" : "AND"
      this.emitRuleUpdate()
    },

    clearNewEntryData(nesi) {
      this.newEntryItems = ''
      this.newEntryCategory = 'ip'
      this.newEntrySectionIndex = nesi
    },

    totalPages(section) {
      return Math.ceil(this.sectionTotalEntries(section) / this.rowsPerPage)
    },

    sectionTotalEntries(section) {
      return section?.entries?.length || 0
    },

    dualCell(cell) {
      if (this.ld.isArray(cell)) {
        return `${cell[0]}: ${cell[1]}`
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
      // Vue.set(this.sectionsCurrentPageIndex, this.localRule.sections.length - 1, 1)
      this.clearNewEntryData(this.localRule.sections.length-1)
      this.emitRuleUpdate()
    },

    removeSection(sectionIndex) {
      this.localRule.sections.splice(sectionIndex, 1)
      this.sectionsCurrentPageIndex.splice(sectionIndex, 1)
      this.emitRuleUpdate()
    },

    addEntry(section) {
      // dual cell
      if (/(args|cookies|headers)/.test(this.newEntryCategory)) {
        let entries = this.newEntryItems.trim().split('\n')
        if (entries.length > 1) {
          let a = entries[0].trim(),
              b = entries[1].trim(),
              annotation = entries.length >= 3 ? entries[2].trim() : null

          section.entries.push([this.newEntryCategory, [a, b], annotation])
        }
      }
      // single line entry
      else {
        this.ld.each(this.newEntryItems.split('\n'), (line) => {
          let [entry, annotation] = line.trim().split('#')
          annotation = annotation && annotation.trim()
          section.entries.push([this.newEntryCategory, entry.trim(), annotation])
        })
      }
      if (this.sectionContainsSameCategoryItems(section)) {
        section.relation = 'OR'
      }
      this.clearNewEntryData(-1)
      this.emitRuleUpdate()
    },

    removeEntry(section, sectionIndex, entry_idx) {
      let pointer = ((this.sectionsCurrentPageIndex[sectionIndex] - 1) * this.rowsPerPage) + entry_idx
      section.entries.splice(pointer, 1)
      if (section.entries.length === 0) {
        this.removeSection(sectionIndex)
      }
      this.emitRuleUpdate()
    },
  }
}
</script>
<style scoped>
.pointer { cursor: pointer; }

.section {
  padding: initial;
}

.section > .entries-table {
  margin-bottom: 0rem;
}

.is-80-px {
  min-width: 80px;
  max-width: 80px;
  width: 80px;
}

.is-48-px {
  min-width: 48px;
  max-width: 48px;
  width: 48px;
}

.relation-selection-wrapper {
  text-align: center;
  margin-bottom: 1rem;
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

.section-relation-toggle {
  cursor: pointer;
}

.grey {
  color: hsl(0, 0%, 48%)
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
</style>
