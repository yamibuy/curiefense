import FlowControlEditor from '@/doc-editors/FlowControlEditor'
import {beforeEach, describe, expect, test} from '@jest/globals'
import {mount, shallowMount} from '@vue/test-utils'
import LimitOption from '@/components/LimitOption'
import LimitAction from '@/components/LimitAction'
import Vue from 'vue'

describe('FlowControlEditor.vue', () => {
    let docs
    let wrapper
    beforeEach(() => {
        docs = [
            {
                'exclude': ['devops', 'internal'],
                'include': ['china'],
                'name': 'flow control',
                'key': [
                    {'headers': 'something'}
                ],
                'sequence': [
                    {
                        'method': 'GET',
                        'uri': '/login',
                        'cookies': {
                            'foo': ['bar', 'annotation']
                        },
                        'headers': {},
                        'args': {}
                    },
                    {
                        'method': 'POST',
                        'uri': '/login',
                        'cookies': {
                            'foo': ['bar', 'hello']
                        },
                        'headers': {
                            'test': ['one']
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
        const onUpdate = (doc) => {
            wrapper.setProps({selectedDoc: doc})
        }
        wrapper = shallowMount(FlowControlEditor, {
            propsData: {
                selectedDoc: docs[0]
            },
            listeners: {
                update: onUpdate
            }
        })
    })

    describe('form data', () => {
        test('should have correct ID displayed', () => {
            expect(wrapper.find('.document-id').text()).toEqual(docs[0].id)
        })

        test('should have correct name in input', () => {
            expect(wrapper.find('.document-name').element.value).toEqual(docs[0].name)
        })

        test('should have correct ttl in input', () => {
            expect(wrapper.find('.document-ttl').element.value).toEqual(docs[0].ttl.toString())
        })

        test('should have limit option component with correct data', () => {
            const wantedType = Object.keys(docs[0].key[0])[0]
            const wantedValue = Object.values(docs[0].key[0])[0]
            const limitOptionComponent = wrapper.findAllComponents(LimitOption).at(0)
            const actualType = limitOptionComponent.vm.option.type
            const actualValue = limitOptionComponent.vm.option.key
            expect(actualType).toEqual(wantedType)
            expect(actualValue).toEqual(wantedValue)
        })

        test('should have limit action component with correct data', () => {
            const limitActionComponent = wrapper.findComponent(LimitAction)
            expect(limitActionComponent.vm.action).toEqual(docs[0].action)
        })

        test('should have correct tags in include filter', () => {
            const includeFilterColumn = wrapper.find('.include-filter-column')
            const tagCells = includeFilterColumn.findAll('.tag-cell')
            expect(tagCells.at(0).text()).toEqual(docs[0].include[0])
            expect(tagCells.length).toEqual(1)
        })

        test('should have correct tags in exclude filter', () => {
            const excludeFilterColumn = wrapper.find('.exclude-filter-column')
            const tagCells = excludeFilterColumn.findAll('.tag-cell')
            expect(tagCells.at(0).text()).toEqual(docs[0].exclude[0])
            expect(tagCells.at(1).text()).toEqual(docs[0].exclude[1])
            expect(tagCells.length).toEqual(2)
        })
    })

    describe('count by key', () => {
        test('should add key when addKey button is clicked', async () => {
            const addKeyButton = wrapper.find('.add-key-button')
            addKeyButton.trigger('click')
            await Vue.nextTick()
            const wantedType = Object.keys(docs[0].key[1])[0]
            const wantedValue = Object.values(docs[0].key[1])[0]
            const limitOptionComponent = wrapper.findAllComponents(LimitOption).at(0)
            const actualType = limitOptionComponent.vm.option.type
            const actualValue = limitOptionComponent.vm.option.key
            expect(actualType).toEqual(wantedType)
            expect(actualValue).toEqual(wantedValue)
        })
    })

    describe('sequence list', () => {
        describe('add section button', () => {
            test('should add empty section', async () => {
                const addSectionButton = wrapper.find('.new-sequence-button')
                addSectionButton.trigger('click')
                await Vue.nextTick()
                const tables = wrapper.findAll('.sequence-entries-table')
                expect(tables.length).toEqual(3)
            })
        })

        describe('remove section button', () => {
            test('should remove section', async () => {
                const removeSectionButton = wrapper.find('.remove-section-button')
                removeSectionButton.trigger('click')
                await Vue.nextTick()
                const tables = wrapper.findAll('.sequence-entries-table')
                expect(tables.length).toEqual(1)
            })

            test('should not have the option to remove section if no sections exist', () => {
                docs[0].sequence = []
                wrapper = mount(FlowControlEditor, {
                    propsData: {
                        selectedDoc: docs[0],
                    }
                })
                const removeSectionButton = wrapper.find('.remove-section-button')
                expect(removeSectionButton.element).toBeUndefined()
            })
        })

        describe('add entry button', () => {
            test('should open new entry row', async () => {
                const table = wrapper.findAll('.sequence-entries-table').at(0)
                const addEntryButton = table.find('.add-entry-button')
                addEntryButton.trigger('click')
                await Vue.nextTick()
                const newEntryRow = table.find('.new-entry-row')
                expect(newEntryRow.element).toBeDefined()
            })

            test('should add new entries from multi-line input when confirm button is clicked', async () => {
                const table = wrapper.findAll('.sequence-entries-table').at(0)
                const addEntryButton = table.find('.add-entry-button')
                addEntryButton.trigger('click')
                await Vue.nextTick()
                const newEntryRow = table.find('.new-entry-row')
                const typeSelection = newEntryRow.find('.new-entry-type-selection')
                typeSelection.trigger('click')
                const options = typeSelection.findAll('option')
                options.at(0).element.selected = true
                typeSelection.trigger('change')
                await Vue.nextTick()
                const newEntryTextarea = newEntryRow.find('.new-entry-textarea')
                newEntryTextarea.setValue('something\nright\nhere')
                const confirmAddEntryButton = table.find('.confirm-add-entry-button')
                confirmAddEntryButton.trigger('click')
                await Vue.nextTick()
                const entriesRows = wrapper.findAll('.sequence-entries-table').at(0).findAll('.sequence-entry-row')
                expect(entriesRows.length).toEqual(4)
                expect(entriesRows.at(2).text()).toContain('Header')
                expect(entriesRows.at(2).text()).toContain('something: right')
                expect(entriesRows.at(2).text()).toContain('here')
            })

            test('should trim and add new entries from multi-line input when confirm button is clicked if has too many lines', async () => {
                const table = wrapper.findAll('.sequence-entries-table').at(0)
                const addEntryButton = table.find('.add-entry-button')
                addEntryButton.trigger('click')
                await Vue.nextTick()
                const newEntryRow = table.find('.new-entry-row')
                const typeSelection = newEntryRow.find('.new-entry-type-selection')
                typeSelection.trigger('click')
                const options = typeSelection.findAll('option')
                options.at(0).element.selected = true
                typeSelection.trigger('change')
                await Vue.nextTick()
                const newEntryTextarea = newEntryRow.find('.new-entry-textarea')
                newEntryTextarea.setValue('something\n11\n22\n33\n44\n55\n66')
                const confirmAddEntryButton = table.find('.confirm-add-entry-button')
                confirmAddEntryButton.trigger('click')
                await Vue.nextTick()
                const entriesRows = wrapper.findAll('.sequence-entries-table').at(0).findAll('.sequence-entry-row')
                expect(entriesRows.length).toEqual(4)
                expect(entriesRows.at(2).text()).toContain('Header')
                expect(entriesRows.at(2).text()).toContain('something: 11')
                expect(entriesRows.at(2).text()).toContain('22')
            })

            test('should not add new entries from multi-line input when confirm button is clicked if has too few lines', async () => {
                const table = wrapper.findAll('.sequence-entries-table').at(0)
                const addEntryButton = table.find('.add-entry-button')
                addEntryButton.trigger('click')
                await Vue.nextTick()
                const newEntryRow = table.find('.new-entry-row')
                const typeSelection = newEntryRow.find('.new-entry-type-selection')
                typeSelection.trigger('click')
                const options = typeSelection.findAll('option')
                options.at(0).element.selected = true
                typeSelection.trigger('change')
                await Vue.nextTick()
                const newEntryTextarea = newEntryRow.find('.new-entry-textarea')
                newEntryTextarea.setValue('something')
                const confirmAddEntryButton = table.find('.confirm-add-entry-button')
                confirmAddEntryButton.trigger('click')
                await Vue.nextTick()
                const entriesRows = wrapper.findAll('.sequence-entries-table').at(0).findAll('.sequence-entry-row')
                expect(entriesRows.length).toEqual(3)
            })
        })

        describe('remove entry button', () => {
            test('should remove entry', async () => {
                const table = wrapper.findAll('.sequence-entries-table').at(0)
                const removeEntryButton = table.find('.remove-entry-button')
                removeEntryButton.trigger('click')
                await Vue.nextTick()
                const entriesRows = wrapper.findAll('.sequence-entries-table').at(0).findAll('.sequence-entry-row')
                expect(entriesRows.length).toEqual(2)
            })
        })
    })
})
