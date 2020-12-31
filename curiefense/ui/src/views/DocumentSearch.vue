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
                    <select v-model="selectedBranch"
                            @change="switchBranch"
                            class="branch-selection">
                      <option v-for="name in branchNames"
                              :key="name"
                              :value="name">
                        {{ name }}
                      </option>
                    </select>
                  </div>
                </div>
                <div class="control">
                  <div class="select is-small">
                    <select v-model="selectedSearchType"
                            class="doc-type-selection">
                      <option v-for="(searchType, propertyName) in searchTypeMap"
                              :key="propertyName"
                              :value="propertyName">
                        {{ searchType.title }}
                      </option>
                    </select>
                  </div>
                </div>
                <div class="control has-icons-left">
                  <input class="input is-small search-input"
                         placeholder="Search"
                         v-model="searchValueDebounced"/>
                  <span class="icon is-small is-left has-text-grey-light"><i class="fa fa-search"></i></span>
                </div>
              </div>
            </div>

            <div class="column">

            </div>
          </div>
        </div>
      </div>

      <hr/>

      <div class="content document-editor-wrapper"
           v-if="true">
        <table class="table">
          <thead>
          <tr>
            <th class="is-size-7 width-100px">Type</th>
            <th class="is-size-7 width-150px">ID</th>
            <th class="is-size-7 width-200px">Name</th>
            <th class="is-size-7 width-200px">Description</th>
            <th class="is-size-7 width-200px">Tags</th>
            <th class="is-size-7 width-150px">Connections</th>
            <th class="is-size-7 width-50px"></th>
          </tr>
          </thead>
          <tbody>
          <tr v-for="(doc, index) in filteredDocs"
              :key="index"
              @mouseleave="mouseLeave()"
              @mouseover="mouseOver(index)">
            <td class="is-size-7 is-vcentered py-3 ellipsis width-100px"
                :title="doc.docType"
                v-html="highlightSearchValue(doc.docType)">
            </td>
            <td class="is-size-7 is-vcentered py-3 ellipsis width-150px"
                :title="doc.id"
                v-html="highlightSearchValue(doc.id)">
            </td>
            <td class="is-size-7 is-vcentered py-3 ellipsis width-200px"
                :title="doc.name"
                v-html="highlightSearchValue(doc.name)">
            </td>
            <td class="is-size-7 is-vcentered py-3 width-200px"
                :title="doc.notes || doc.description">
              <div class="vertical-scroll scrollbox-shadowed"
                   v-html="highlightSearchValue(doc.notes || doc.description)">
              </div>
            </td>
            <td class="is-size-7 is-vcentered py-3 width-200px"
                :title="doc.tags">
              <div class="vertical-scroll scrollbox-shadowed"
                   v-html="highlightSearchValue(doc.tags)">
              </div>
            </td>
            <td class="is-size-7 is-vcentered py-3 width-150px">
              <div class="vertical-scroll scrollbox-shadowed"
                   v-html="connectionsDisplayText(doc)">
              </div>
            </td>
            <td class="is-size-7 is-vcentered py-3 width-10px">
              <p class="control has-text-centered" v-if="rowOverIndex === index">
                <a class="button is-small link-button"
                   @click="goToDocument(doc)"
                   title="Go to document">
                    <span class="icon is-small">
                      <i class="fas fa-link"></i>
                    </span>
                </a>
              </p>
            </td>
          </tr>
          </tbody>
        </table>
      </div>

      <!--      <div class="content no-data-wrapper"-->
      <!--           v-else>-->
      <!--        <div v-if="loadingDocCounter > 0">-->
      <!--          <button class="button is-outlined is-text is-small is-loading document-loading">-->
      <!--            Loading-->
      <!--          </button>-->
      <!--        </div>-->
      <!--        <div v-else-->
      <!--             class="no-data-message">-->
      <!--          No data found!-->
      <!--        </div>-->
      <!--      </div>-->
    </div>
  </div>
</template>

<script>

import ACLEditor from '@/doc-editors/ACLEditor.vue'
import WAFEditor from '@/doc-editors/WAFEditor.vue'
import URLMapsEditor from '@/doc-editors/URLMapsEditor.vue'
import RateLimitsEditor from '@/doc-editors/RateLimitsEditor.vue'
import ProfilingListEditor from '@/doc-editors/ProfilingListEditor.vue'
import FlowControlEditor from '@/doc-editors/FlowControlEditor'
import RequestsUtils from '@/assets/RequestsUtils'
import _ from 'lodash'

export default {

  name: 'DocumentSearch',
  props: {},
  components: {},
  data() {
    return {
      configs: [],
      docs: [],
      selectedBranch: null,
      // Starting with the first search type in searchTypeMap
      selectedSearchType: 'all',
      searchValue: '',
      rowOverIndex: null,

      searchTypeMap: {
        'all': {
          title: 'All',
          filter: (doc) => {
            const isFoundDocType = this.searchTypeMap['doctype'].filter(doc)
            const isFoundID = this.searchTypeMap['id'].filter(doc)
            const isFoundName = this.searchTypeMap['name'].filter(doc)
            const isFoundDescription = this.searchTypeMap['description'].filter(doc)
            const isFoundTags = this.searchTypeMap['tags'].filter(doc)
            const isFoundConnections = this.searchTypeMap['connections'].filter(doc)
            return isFoundDocType || isFoundID || isFoundName || isFoundDescription || isFoundTags || isFoundConnections
          }
        },
        'doctype': {
          title: 'Document Type',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.docType)
          }
        },
        'id': {
          title: 'ID',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.id)
          }
        },
        'name': {
          title: 'Name',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.name)
          }
        },
        'description': {
          title: 'Description',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.notes || doc.description)
          }
        },
        'tags': {
          title: 'Tags',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.tags)
          }
        },
        'connections': {
          title: 'Connections',
          filter: (doc) => {
            return this.searchValueRegex.test(doc.connections)
          }
        }
      },

      // Order is important, we load [urlmaps] before [aclpolicies, wafpolicies, ratelimits] so we can pull all references correctly
      componentsMap: {
        'urlmaps': {component: URLMapsEditor, title: 'URL Maps'},
        'aclpolicies': {component: ACLEditor, title: 'ACL Policies'},
        'flowcontrol': {component: FlowControlEditor, title: 'Flow Control'},
        'tagrules': {component: ProfilingListEditor, title: 'Tag Rules'},
        'ratelimits': {component: RateLimitsEditor, title: 'Rate Limits'},
        'wafpolicies': {component: WAFEditor, title: 'WAF Policies'}
      },

      // Referenced IDs of [aclpolicies, wafpolicies, ratelimits] in [urlmaps]
      referencedACL: {},
      referencedWAF: {},
      referencedLimit: {},
    }
  },
  computed: {

    branchNames() {
      return this.ld.sortBy(this.ld.map(this.configs, 'id'))
    },

    filteredDocs() {
      return this.docs.filter((doc) => {
        return this.searchTypeMap[this.selectedSearchType].filter(doc, this.searchValueDebounced)
      })
    },

    searchValueRegex() {
      return new RegExp(this.searchValue, 'gi')
    },

    searchValueDebounced: {
      get() {
        return this.searchValue
      },
      set: _.debounce(function (newValue) {
        this.searchValue = newValue
      }, 300)
    }

  },

  methods: {

    async loadConfigs() {
      // store configs
      let configs
      try {
        const response = await RequestsUtils.sendRequest('GET', 'configs/')
        configs = response.data
      } catch (err) {
        console.log('Error while attempting to get configs')
        console.log(err)
      }
      console.log('loaded configs: ', configs)
      this.configs = configs
      // pick first branch name as selected
      this.selectedBranch = this.branchNames[0]
      // load all docs
      const docTypes = Object.keys(this.componentsMap)
      for (let i = 0; i < docTypes.length; i++) {
        let doctype = docTypes[i]
        let branch = this.selectedBranch
        try {
          const response = await RequestsUtils.sendRequest('GET', `configs/${branch}/d/${doctype}/`)
          for (let j = 0; j < response.data.length; j++) {
            const doc = response.data[j]
            doc.docType = this.componentsMap[doctype].title
            doc.tags = doc.tags ? doc.tags.join(', ').toLowerCase() : ''
            // Build connections based on document type
            if (doctype === 'urlmaps') {
              this.buildURLMapConnections(doc)
              this.saveWafAclLimitConnections(doc)
            }
            if (doctype === 'aclpolicies') {
              this.buildWafAclLimitConnections(doc, this.referencedACL)
            }
            if (doctype === 'wafpolicies') {
              this.buildWafAclLimitConnections(doc, this.referencedWAF)
            }
            if (doctype === 'ratelimits') {
              this.buildWafAclLimitConnections(doc, this.referencedLimit)
            }
            this.docs.push(doc)
          }
        } catch (err) {
          console.log('Error while attempting to load documents')
          console.log(err)
        }
      }
    },

    buildURLMapConnections(doc) {
      const connectedACL = []
      const connectedWAF = []
      const connectedRateLimits = []
      for (let i = 0; i < doc.map.length; i++) {
        const map = doc.map[i]
        connectedACL.push(map.acl_profile)
        connectedWAF.push(map.waf_profile)
        for (let j = 0; j < map.limit_ids.length; j++) {
          connectedRateLimits.push(map.limit_ids[j])
        }
      }
      doc.connectedACL = connectedACL
      doc.connectedWAF = connectedWAF
      doc.connectedRateLimits = connectedRateLimits
      doc.connections = [].concat(connectedACL, connectedWAF, connectedRateLimits)
    },

    buildWafAclLimitConnections(doc, referencedArray) {
      if (!referencedArray[doc.id] || referencedArray[doc.id].length === 0) {
        return
      }
      doc.connectedURLMaps = referencedArray[doc.id]
      doc.connections = referencedArray[doc.id]
    },

    saveWafAclLimitConnections(doc) {
      for (let i = 0; i < doc.map.length; i++) {
        const map = doc.map[i]
        // initialize array if needed
        if (!this.referencedACL[map.acl_profile] || this.referencedACL[map.acl_profile].length === 0) {
          this.referencedACL[map.acl_profile] = []
        }
        // add map id to referenced acl
        this.referencedACL[map.acl_profile].push(doc.id)
        // initialize array if needed
        if (!this.referencedWAF[map.waf_profile] || this.referencedWAF[map.waf_profile].length === 0) {
          this.referencedWAF[map.waf_profile] = []
        }
        // add map id to referenced waf
        this.referencedWAF[map.waf_profile].push(doc.id)
        for (let j = 0; j < map.limit_ids.length; j++) {
          // initialize array if needed
          if (!this.referencedLimit[map.limit_ids] || this.referencedLimit[map.limit_ids].length === 0) {
            this.referencedLimit[map.limit_ids[j]] = []
          }
          // add map id to referenced rate limit
          this.referencedLimit[map.limit_ids[j]].push(doc.id)
        }
      }
    },

    highlightSearchValue(text) {
      if (!this.searchValue) {
        return text
      }
      return text && text.replace(this.searchValueRegex, (str) => {
        return `<mark>${str}</mark>`
      })
    },

    connectionsDisplayText(doc) {
      let connections = ''
      if (doc.connectedACL && doc.connectedACL.length > 0) {
        const highlightedConnectedEntities = this.highlightSearchValue(doc.connectedACL.join('<br/>'))
        connections = connections.concat(`<b>${this.componentsMap['aclpolicies'].title}:</b><br/>${highlightedConnectedEntities}</br>`)
      }
      if (doc.connectedWAF && doc.connectedWAF.length > 0) {
        const highlightedConnectedEntities = this.highlightSearchValue(doc.connectedWAF.join('<br/>'))
        connections = connections.concat(`<b>${this.componentsMap['wafpolicies'].title}:</b><br/>${highlightedConnectedEntities}</br>`)
      }
      if (doc.connectedRateLimits && doc.connectedRateLimits.length > 0) {
        const highlightedConnectedEntities = this.highlightSearchValue(doc.connectedRateLimits.join('<br/>'))
        connections = connections.concat(`<b>${this.componentsMap['ratelimits'].title}:</b><br/>${highlightedConnectedEntities}</br>`)
      }
      if (doc.connectedURLMaps && doc.connectedURLMaps.length > 0) {
        const highlightedConnectedEntities = this.highlightSearchValue(doc.connectedURLMaps.join('<br/>'))
        connections = connections.concat(`<b>${this.componentsMap['urlmaps'].title}:</b><br/>${highlightedConnectedEntities}</br>`)
      }
      return connections
    },

    async switchBranch() {
      await this.initDocTypes()
    },

    goToDocument(doc) {
      console.log(doc)
    },

    mouseLeave() {
      this.rowOverIndex = null
    },

    mouseOver(index) {
      this.rowOverIndex = index
    },

  },

  async created() {
    await this.loadConfigs()
  }

}

</script>
<style scoped>
.vertical-scroll {
  max-height: 4.5rem;
}

.no-data-wrapper {
  /* Magic number! The page looks empty without content */
  min-height: 50vh;
  /* Magic number! Delayed the display of loading indicator as to not display it in short loads */
  animation: delayedDisplay 300ms;
}

@keyframes delayedDisplay {
  0% {
    opacity: 0
  }
  50% {
    opacity: 0
  }
  51% {
    opacity: 1
  }
  100% {
    opacity: 1
  }
}

</style>
