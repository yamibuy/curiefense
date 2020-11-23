<template>
  <div class="card">
    <div class="card-content">
      <div class="content">
        <div class="field">
          <label class="label is-small is-inline-block">Entries Relation</label>
          <a v-if="editable && recursive"
             class="has-text-grey-dark is-small is-pulled-right is-danger is-light"
             title="Delete this entries block"
             @click="removeEntryBlock">
            <span class="icon is-small"><i class="fas fa-trash"></i></span>
          </a>
          <a v-if="editable"
             class="has-text-grey-dark is-small is-pulled-right"
             title="Add new entries block"
             @click="addEntryBlock">
            <span class="icon is-small"><i class="fas fa-plus"></i></span>
          </a>
          <div class="control is-expanded">
            <div class="select is-small is-size-7 is-fullwidth">
              <select v-model="relationList.relation">
                <option value="AND">AND</option>
                <option value="OR">OR</option>
              </select>
            </div>
          </div>
          <p class="help">Logical relation between different entries in different categories.</p>
        </div>
        <div v-if="isListLowestLevel">
          <table class="table is-narrow is-fullwidth" v-if="newEntry && editable">
            <thead>
            <tr>
              <th class="is-size-7">Category</th>
              <th class="is-size-7">Entry</th>
              <th class="is-size-7 is-48-px">
                <a class="is-small has-text-grey" title="cancel" @click="newEntry = false">cancel</a>
              </th>
            </tr>
            </thead>
            <tbody>
            <tr>
              <td class="is-size-7">
                <div class="select is-small is-fullwidth">
                  <select v-model="newEntryCategory" class="select">
                    <option v-for="(entry, category) in listEntryTypes" :key="category" :value="category">
                      {{ entry.title }}
                    </option>
                  </select>
                </div>
              </td>
              <td class="is-size-7">
                          <textarea rows="3"
                                    class="textarea is-small is-fullwidth"
                                    :placeholder="inputDescription"
                                    v-model="newEntryItems"></textarea>
              </td>
              <th class="is-size-7 is-48-px">
                <a class="is-small has-text-grey" title="add entry" @click="addEntry">add</a>
              </th>
            </tr>
            </tbody>
          </table>
          <hr/>
          <table class="table is-narrow">
            <thead>
            <tr>
              <th class="is-size-7 is-48-px">
              <th class="is-size-7">Category</th>
              <th class="is-size-7">Entry</th>
              <th class="is-size-7">Annotation</th>
              <th class=" is-size-7 is-48-px">
                <a v-if="editable"
                   class="has-text-grey-dark is-small is-pulled-right" title="Add new entry" @click="newEntry = true">
                  <span class="icon is-small"><i class="fas fa-plus"></i></span>
                </a>
              </th>
            </tr>
            </thead>
            <tbody>
            <tr v-for="(entry,idx) in selectedPage" :key="idx">
              <td class="is-size-7 is-48-px has-text-right has-text-grey-light">
                {{ ((idx + 1) + ((currentPage - 1) * rowsPerPage)) }}
              </td>
              <td class="is-size-7">{{ listEntryTypes[entry[0]].title }}</td>
              <td class="is-size-7"><span v-html="dualCell(entry[1])"></span></td>
              <td class="is-size-7" :title="entry[2]">{{ entry[2] ? entry[2].substr(0, 40) : '' }}</td>
              <td class="is-size-7 is-48-px">
                <a v-if="editable"
                   class="is-small has-text-grey" title="remove entry"
                   @click="removeEntry(currentPage, idx)">
                  remove
                </a>
              </td>
            </tr>
            <tr v-if="totalPages > 1">
              <td colspan="5">
                <nav class="pagination is-small" role="navigation" aria-label="pagination">
                  <a :disabled="currentPage === 1" class="is-pulled-left pagination-previous"
                     @click="navigate(currentPage - 1)">Previous Page</a>
                  <a :disabled="currentPage === totalPages" class="is-pulled-right pagination-next"
                     @click="navigate(currentPage + 1)">Next page</a>
                </nav>
              </td>
            </tr>
            </tbody>
          </table>
        </div>
        <div v-else>
          <entries-relation-list v-for="(entry, id) in localEntries"
                                 :key="id"
                                 :relation-list="entry"
                                 :editable="editable"
                                 :recursive="true"
                                 @delete="removeEntryBlock($event, id)">
          </entries-relation-list>
        </div>
      </div>
    </div>
  </div>

</template>

<script>

export default {
  name: 'EntriesRelationList',

  props: {
    relationList: {
      type: Object,
      default: () => {
        return {
          relation: 'OR',
          entries: []
        }
      },
      validator(val) {
        const validateRelationList = (value) => {
          if (!value || !value.relation || !value.entries) {
            return false
          }
          const isRelationValid = ['OR', 'AND'].includes(value.relation.toUpperCase())
          let isListValidEntries = true
          let isListValidEntriesBlocks = true
          let isListValid = true
          // Validate that all entries are either arrays with correct length or relationList objects
          for (let i = 0; i < value.entries.length; i++) {
            const entry = value.entries[i]
            if (!entry || entry.length < 2 || entry.length > 3) {
              isListValidEntries = false
            }
            if (!entry || !validateRelationList(entry)) {
              isListValidEntriesBlocks = false
            }
            isListValid = isListValidEntries || isListValidEntriesBlocks
            // If the list is invalid, there is no need to continue iterations
            if (!isListValid) {
              break
            }
          }
          return isRelationValid && isListValid
        }
        return validateRelationList(val)
      }
    },
    editable: Boolean,
    recursive: Boolean,
  },

  data() {
    return {
      rowsPerPage: 20,
      currentPage: 1,
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
      newEntry: false,
      // newEntryCategory - start with most common category - IP
      newEntryCategory: 'ip',
      newEntryItems: '',
      localEntries: []
    }
  },

  computed: {
    inputDescription() {
      if ((new RegExp('(args|cookies|headers)')).test(this.newEntryCategory)) {
        return '1st line: NAME\n2nd line: VALUE\n3rd line: optional annotation'
      }
      return 'One entry per line, use \'#\' for annotation\ne.g. 12.13.14.15 #San Jose Office'
    },

    totalPages() {
      return Math.ceil(this.listTotalEntries / this.rowsPerPage)
    },

    listTotalEntries() {
      return this.localEntries.length || 0
    },

    isListLowestLevel() {
      return !this.listTotalEntries || this.localEntries[0].constructor.name === 'Array'
    },

    selectedPage() {
      if (this.listTotalEntries === 0) {
        return []
      }

      let entries = this.localEntries
      entries = this.ld.slice(entries, (this.currentPage - 1) * this.rowsPerPage, this.rowsPerPage * this.currentPage)
      return entries
    },
  },

  watch: {
    relationList: {
      handler: function (newVal) {
        this.localEntries = newVal.entries || []
      },
      immediate: true,
      deep: true
    }
  },

  methods: {
    dualCell(cell) {
      if (this.ld.isArray(cell)) {
        return `name: ${cell[0]}<br/>value: ${cell[1]}`
      } else {
        return cell
      }
    },

    navigate(pageNum) {
      if (pageNum >= 1 && pageNum <= this.totalPages) {
        this.currentPage = pageNum
      }
    },

    addEntryBlock() {
      if (!this.isListLowestLevel) {
        this.localEntries.unshift({
          relation: 'OR',
          entries: []
        })
      } else {
        const currentEntries = this.ld.cloneDeep(this.localEntries)
        this.localEntries.splice(0, this.localEntries.length)
        this.localEntries.unshift({
          relation: this.relationList.relation,
          entries: currentEntries
        })
      }
    },

    removeEntryBlock(event, index) {
      if (index === undefined) {
        this.newEntryItems = ''
        this.newEntry = false
        this.$emit('delete', event)
        return
      }
      event.stopPropagation()
      this.localEntries.splice(index, 1)
    },

    addEntry() {
      // dual cell
      if ((new RegExp('(args|cookies|headers)')).test(this.newEntryCategory)) {
        let entries = this.newEntryItems.trim().split('\n')
        if (entries.length === 3 || entries.length === 2) {
          this.localEntries.unshift([this.newEntryCategory, [entries[0].trim(), entries[1].trim()], entries[2].trim()])
        }
      }
      // single line entry
      else {
        this.ld.each(this.newEntryItems.split('\n'), (line) => {
          let [entry, annotation] = line.trim().split('#')
          annotation = annotation && annotation.trim()
          this.localEntries.unshift([this.newEntryCategory, entry.trim(), annotation])
        })
      }
      this.newEntryItems = ''
      this.newEntry = false
    },

    removeEntry(currentPage, idx) {
      let pointer = ((this.currentPage - 1) * this.rowsPerPage) + idx
      this.localEntries.splice(pointer, 1)
    },
  }
}
</script>
