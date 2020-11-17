<template>
  <div>
    <div class="field">
      <label class="label is-small">Entries Relation</label>
      <div class="control is-expanded">
        <div class="select is-small is-size-7 is-fullwidth">
          <select v-model="relationList.relation">
            <option value="AND">AND</option>
            <option value="OR">OR</option>
          </select>
        </div>
      </div>
      <p class="help">Logical relations between different entries in different categories.</p>
    </div>
    <!--    <div v-if="newEntry && editable">-->
    <!--      <table class="table is-narrow is-fullwidth">-->
    <!--        <thead>-->
    <!--        <tr>-->
    <!--          <th class="is-size-7">Category</th>-->
    <!--          <th class="is-size-7">Entry</th>-->
    <!--          <th class="is-size-7 is-48-px">-->
    <!--            <a class="is-small has-text-grey" title="cancel" @click="newEntry = false">cancel</a>-->
    <!--          </th>-->
    <!--        </tr>-->
    <!--        </thead>-->
    <!--        <tbody>-->
    <!--        <tr>-->
    <!--          <td class="is-size-7">-->
    <!--            <div class="select is-small is-fullwidth">-->
    <!--              <select v-model="newEntry_category" class="select">-->
    <!--                <option v-for="(entry, category) in list_entry_types" :key="category" :value="category">{{-->
    <!--                    entry.title-->
    <!--                  }}-->
    <!--                </option>-->
    <!--              </select>-->
    <!--            </div>-->
    <!--          </td>-->
    <!--          <td class="is-size-7">-->
    <!--                      <textarea rows="3"-->
    <!--                                class="textarea is-small is-fullwidth"-->
    <!--                                :placeholder="inputDescription"-->
    <!--                                v-model="newEntry_items"></textarea>-->
    <!--          </td>-->
    <!--          <th class="is-size-7 is-48-px">-->
    <!--            <a class="is-small has-text-grey" title="add entry" @click="addEntry">add</a>-->
    <!--          </th>-->
    <!--        </tr>-->
    <!--        </tbody>-->
    <!--      </table>-->
    <!--      <hr/>-->
    <!--    </div>-->
    <div v-if="isListLowestLevel">
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
        <tr v-for="(entry,idx) in selectedDocPage" :key="idx">
          <td class="is-size-7 is-48-px has-text-right has-text-grey-light">
            {{ ((idx + 1) + ((currentPage - 1) * rowsPerPage)) }}
          </td>
          <td class="is-size-7">{{ list_entry_types[entry[0]].title }}</td>
          <td class="is-size-7"><span v-html="dualCell(entry[1])"></span></td>
          <td class="is-size-7" :title="entry[2]">{{ entry[2] ? entry[2].substr(0, 40) : '' }}</td>
          <td class="is-size-7 is-48-px">
            <a v-if="editable "
               class="is-small has-text-grey" title="remove entry"
               @click="removeEntry(currentPage, idx)"
            >remove</a>
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
      <entries-relation-list v-for="(entry, id) in relationList.list"
                             :key="id"
                             :relation-list="entry">
      </entries-relation-list>
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
          list: []
        }
      },
      // relation: {
      //   type: String,
      //   validator(val) {
      //     return ['OR', 'AND'].includes(val.toUpperCase())
      //   }
      // },
      // list: {
      //   type: Array,
      //   validator(val) {
      //     // TODO: Validation
      //     console.log(val)
      //     const isEntriesRelationList = true
      //     const isEntriesList = true
      //     return isEntriesRelationList || isEntriesList
      //   }
      // }
    },
    editable: Boolean
  },
  data() {
    return {
      rowsPerPage: 20,
      currentPage: 1,
      newEntry: false,
      list_entry_types: {
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
    }
  },
  computed: {
    totalPages() {
      return Math.ceil(this.listTotalEntries / this.rowsPerPage)
    },

    listTotalEntries() {
      return this.selectedDoc?.entries?.length
    },

    isListLowestLevel() {
      // TODO: check for lowest level e.g. entries list
      return true
    },

    selectedDocPage() {
      console.log('@@@@@@@@@')
      console.log(this.relationList.list)
      if (this.relationList?.list?.length === 0) {
        return []
      }

      let entries = this.relationList.list
      entries = this.ld.slice(entries, (this.currentPage - 1) * this.rowsPerPage, this.rowsPerPage * this.currentPage)
      return entries
    },
  },

  watch: {
    relationList: function (newVal) {
     console.log(newVal)
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

    navigate(pagenum) {
      if (pagenum >= 1 && pagenum <= this.totalPages) {
        this.currentPage = pagenum
      }
    },

    removeEntry(currentPage, idx) {
      let pointer = ((this.currentPage - 1) * this.rowsPerPage) + idx
      this.selectedDoc.entries.splice(pointer, 1)
    },
  }
}
</script>
