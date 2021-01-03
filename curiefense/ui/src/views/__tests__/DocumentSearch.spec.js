import DocumentSearch from '@/views/DocumentSearch'
import {afterEach, beforeEach, describe, expect, jest, test} from '@jest/globals'
import {shallowMount} from '@vue/test-utils'
import axios from 'axios'
import Vue from 'vue'
jest.useFakeTimers()
jest.mock('axios')

describe('DocumentSearch.vue', () => {
    let wrapper
    let gitData
    let aclDocs
    let profilingListDocs
    let urlMapsDocs
    let flowControlDocs
    beforeEach((done) => {
        gitData = ['master']
        aclDocs = [
            {
                'id': '__default__',
                'name': 'default-acl',
                'allow': [],
                'allow_bot': [
                    'google'
                ],
                'deny_bot': [],
                'bypass': [
                    'internal'
                ],
                'deny': [
                    'tor'
                ],
                'force_deny': [
                    'china'
                ]
            },
            {
                'id': '5828321c37e0',
                'name': 'an ACL',
                'allow': [],
                'allow_bot': [
                    'google',
                    'yahoo',
                ],
                'deny_bot': [],
                'bypass': [
                    'devops'
                ],
                'deny': [
                    'tor'
                ],
                'force_deny': [
                    'iran'
                ]
            }
        ]
        profilingListDocs = [
            {
                'id': 'xlbp148c',
                'name': 'API Discovery',
                'source': 'self-managed',
                'mdate': '2020-05-23T00:04:41',
                'notes': 'Default Tag API Requests',
                'active': true,
                'entries_relation': 'OR',
                'tags': [
                    'api'
                ],
                'entries': [
                    [
                        'headers',
                        [
                            'content-type',
                            '.*/(json|xml)'
                        ],
                        'content type'
                    ],
                    [
                        'headers',
                        [
                            'host',
                            '.?ap[ip]\\.'
                        ],
                        'app or api in domain name'
                    ],
                    [
                        'method',
                        '(POST|PUT|DELETE|PATCH)',
                        'Methods'
                    ],
                    [
                        'path',
                        '/api/',
                        'api path'
                    ],
                    [
                        'uri',
                        '/.+\\.json',
                        'URI JSON extention'
                    ]
                ]
            },
            {
                'id': '07656fbe',
                'name': 'devop internal demo',
                'source': 'self-managed',
                'mdate': '2020-05-23T00:04:41',
                'notes': 'this is my own list',
                'active': false,
                'entries_relation': 'OR',
                'tags': [
                    'internal',
                    'devops'
                ],
                'entries': [
                    [
                        'ip',
                        '12.34.56.78/32',
                        'testers'
                    ],
                    [
                        'ip',
                        '98.76.54.0/24',
                        'monitoring'
                    ],
                    [
                        'ip',
                        '!5.4.3.2/32',
                        'old monitoring'
                    ],
                    [
                        'path',
                        '/test/app/status',
                        'monitoring path'
                    ]
                ]
            }
        ]
        urlMapsDocs = [
            {
                'id': '__default__',
                'name': 'default entry',
                'match': '__default__',
                'map': [
                    {
                        'name': 'default',
                        'match': '/',
                        'acl_profile': '5828321c37e0',
                        'acl_active': false,
                        'waf_profile': '__default__',
                        'waf_active': false,
                        'limit_ids': []
                    }
                ]
            }
        ]
        flowControlDocs = [
            {
                'exclude': [],
                'include': ['all'],
                'name': 'flow control',
                'key': [
                    {'headers': 'something'}
                ],
                'sequence': [
                    {
                        'method': 'GET',
                        'uri': '/login',
                        'cookies': {
                            'foo': 'bar'
                        },
                        'headers': {},
                        'args': {}
                    },
                    {
                        'method': 'POST',
                        'uri': '/login',
                        'cookies': {
                            'foo': 'bar'
                        },
                        'headers': {
                            'test': 'one'
                        },
                        'args': {}
                    }
                ],
                'action': {
                    'type': 'default',
                    'params': {}
                },
                'ttl': 60,
                'id': 'c03dabe4b9ca'
            }
        ]
        axios.get.mockImplementation((path) => {
            if (path === '/conf/api/v1/configs/') {
                return Promise.resolve({data: gitData})
            }
            const branch = wrapper.vm.selectedBranch
            if (path === `/conf/api/v1/configs/${branch}/d/aclpolicies/`) {
                return Promise.resolve({data: aclDocs})
            }
            if (path === `/conf/api/v1/configs/${branch}/d/tagrules/`) {
                return Promise.resolve({data: profilingListDocs})
            }
            if (path === `/conf/api/v1/configs/${branch}/d/urlmaps/`) {
                return Promise.resolve({data: urlMapsDocs})
            }
            if (path === `/conf/api/v1/configs/${branch}/d/flowcontrol/`) {
                return Promise.resolve({data: flowControlDocs})
            }
            if (path === `/conf/api/v1/configs/${branch}/d/ratelimits/`) {
                return Promise.resolve({data: []})
            }
            if (path === `/conf/api/v1/configs/${branch}/d/wafpolicies/`) {
                return Promise.resolve({data: []})
            }
            return Promise.resolve({data: []})
        })
        wrapper = shallowMount(DocumentSearch)
        // allow all requests to finish
        setImmediate(() => {
            done()
        })
    })
    afterEach(() => {
        jest.clearAllMocks()
    })

    function isItemInFilteredDocs(item) {
        const isInModel = wrapper.vm.filteredDocs.some((doc) => {
            return doc.id === item.id
        })
        const isInView = wrapper.findAll('.doc-id-cell').filter((w) => {
            return w.text().includes(item.id)
        }).length > 0
        return isInModel && isInView
    }

    function numberOfFilteredDocs() {
        return wrapper.findAll('.result-row').length
    }

    test('should display all documents if not filtered', () => {
        expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
        expect(isItemInFilteredDocs(aclDocs[1])).toBeTruthy()
        expect(isItemInFilteredDocs(profilingListDocs[0])).toBeTruthy()
        expect(isItemInFilteredDocs(profilingListDocs[1])).toBeTruthy()
        expect(isItemInFilteredDocs(urlMapsDocs[0])).toBeTruthy()
        expect(isItemInFilteredDocs(flowControlDocs[0])).toBeTruthy()
        expect(numberOfFilteredDocs()).toEqual(6)
    })

    describe('filters', () => {
        test('should filter correctly with filter all',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(0).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = 'default'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(aclDocs[1])).toBeTruthy()
            expect(isItemInFilteredDocs(profilingListDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(urlMapsDocs[0])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(4)
        })

        test('should filter correctly with filter document type',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(1).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = 'acl'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(aclDocs[1])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(2)
        })

        test('should filter correctly with filter id',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(2).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = '__default__'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(urlMapsDocs[0])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(2)
        })

        test('should filter correctly with filter name',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(3).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = '__default__'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(urlMapsDocs[0])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(2)
        })

        test('should filter correctly with filter description',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(4).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = 'default'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(profilingListDocs[0])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(1)
        })

        test('should filter correctly with filter tags',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(5).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = 'internal'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[0])).toBeTruthy()
            expect(isItemInFilteredDocs(profilingListDocs[1])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(2)
        })

        test('should filter correctly with filter connections',  async() => {
            // switch filter type
            const searchTypeSelection = wrapper.find('.search-type-selection')
            searchTypeSelection.trigger('click')
            const options = searchTypeSelection.findAll('option')
            options.at(6).element.selected = true
            searchTypeSelection.trigger('change')
            await Vue.nextTick()

            const searchInput = wrapper.find('.search-input')
            searchInput.element.value = '__default__'
            searchInput.trigger('input')
            await Vue.nextTick()
            expect(isItemInFilteredDocs(aclDocs[1])).toBeTruthy()
            expect(isItemInFilteredDocs(urlMapsDocs[0])).toBeTruthy()
            expect(numberOfFilteredDocs()).toEqual(2)
        })
    })
})
