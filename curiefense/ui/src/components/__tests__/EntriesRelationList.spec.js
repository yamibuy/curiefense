import EntriesRelationList from '@/components/EntriesRelationList'
import {describe, test, expect, beforeEach, jest, afterEach} from '@jest/globals'
import {mount} from '@vue/test-utils'
import Vue from 'vue'

describe('EntriesRelationList.vue', () => {
    let wrapper
    let entriesRelationData
    let entryData1
    let entryData2
    beforeEach(() => {
        entryData1 = {
            relation: 'or',
            entries: [
                [
                    'uri',
                    '/login'
                ],
                [
                    'uri',
                    '/account'
                ]
            ]
        }
        entryData2 = {
            relation: 'and',
            entries: [
                [
                    'headers',
                    'user-agent',
                    'curl'
                ],
                [
                    'headers',
                    'content-type',
                    'application/json'
                ]
            ]
        }
        entriesRelationData = {
            relation: 'and',
            entries: [
                entryData1,
                entryData2
            ]
        }
        wrapper = mount(EntriesRelationList, {
            propsData: {
                relationList: entriesRelationData,
                editable: true
            }
        })
    })
    afterEach(() => {
        jest.clearAllMocks()
    })

    test('should have a single component rendered for each relation list', () => {
        const components = wrapper.findAllComponents(EntriesRelationList)
        expect(components.length).toEqual(3)
    })

    test('should display correct data from prop to view', () => {
        const wantedEntryData = wrapper.vm.ld.cloneDeep(entryData1.entries)
        const component = wrapper.findAllComponents(EntriesRelationList).at(1)
        const categories = component.findAll('.entry-category')
        const values = component.findAll('.entry-value')
        expect(categories.at(0).text().toLowerCase()).toContain(wantedEntryData[0][0].toLowerCase())
        expect(values.at(0).text().toLowerCase()).toContain(wantedEntryData[0][1].toLowerCase())
        expect(categories.at(1).text().toLowerCase()).toContain(wantedEntryData[1][0].toLowerCase())
        expect(values.at(1).text().toLowerCase()).toContain(wantedEntryData[1][1].toLowerCase())
        expect(entriesRelationData.entries[0].entries).toEqual(wantedEntryData)
    })

    test('should display correct data from prop to view if data changed', async() => {
        const wantedEntryData = ['ip', '1.2.3.4']
        wrapper.vm.relationList = {
            relation: 'and',
            entries: [wantedEntryData]
        }
        await Vue.nextTick()
        const component = wrapper.findAllComponents(EntriesRelationList).at(0)
        const categories = component.findAll('.entry-category')
        const values = component.findAll('.entry-value')
        expect(categories.at(0).text().toLowerCase()).toContain(wantedEntryData[0].toLowerCase())
        expect(values.at(0).text().toLowerCase()).toContain(wantedEntryData[1].toLowerCase())
    })

    describe('large data pagination', () => {
        beforeEach(() => {
            entriesRelationData.entries = [
                ['uri', '/login0'],
                ['uri', '/login1'],
                ['uri', '/login2'],
                ['uri', '/login3'],
                ['uri', '/login4'],
                ['uri', '/login5'],
                ['uri', '/login6'],
                ['uri', '/login7'],
                ['uri', '/login8'],
                ['uri', '/login9'],
                ['uri', '/account0'],
                ['uri', '/account1'],
                ['uri', '/account2'],
                ['uri', '/account3'],
                ['uri', '/account4'],
                ['uri', '/account5'],
                ['uri', '/account6'],
                ['uri', '/account7'],
                ['uri', '/account8'],
                ['uri', '/account9'],
                ['uri', '/about0'],
                ['uri', '/about1'],
                ['uri', '/about2'],
                ['uri', '/about3'],
                ['uri', '/about4'],
                ['uri', '/about5'],
                ['uri', '/about6'],
                ['uri', '/about7'],
                ['uri', '/about8'],
                ['uri', '/about9'],
            ]
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    relationList: entriesRelationData,
                    editable: true
                }
            })
        })

        test('should show 20 entries per page', () => {
            const entryRows = wrapper.findAll('.entry-row')
            expect(entryRows.length).toEqual(20)
        })

        test('should correctly render next page when next page button is clicked', async () => {
            const nextPageButton = wrapper.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            const entryRows = wrapper.findAll('.entry-row')
            expect(entryRows.length).toEqual(10)
        })

        test('should have next page button disabled if currently in last page', async () => {
            const nextPageButton = wrapper.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            expect(nextPageButton.attributes('disabled')).toBeTruthy()
        })

        test('should correctly render prev page when next prev button is clicked', async () => {
            const nextPageButton = wrapper.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            const prevPageButton = wrapper.find('.pagination-previous')
            prevPageButton.trigger('click')
            await Vue.nextTick()
            const entryRows = wrapper.findAll('.entry-row')
            expect(entryRows.length).toEqual(20)
        })

        test('should have prev page button disabled if currently in first page', async () => {
            const prevPageButton = wrapper.find('.pagination-previous')
            expect(prevPageButton.attributes('disabled')).toBeTruthy()
        })
    })

    describe('relationList prop validator', () => {
        let validator
        beforeEach(() => {
            validator = EntriesRelationList.props.relationList.validator
        })

        test('should return true for data in the correct schema', () => {
            const isValid = validator(entriesRelationData)
            expect(isValid).toEqual(true)
        })

        test('should return false for relation not `or` or `and`', () => {
            entriesRelationData.relation = 'unknown value'
            const isValid = validator(entriesRelationData)
            expect(isValid).toEqual(false)
        })

        test('should return false for entries with too few arguments', () => {
            entriesRelationData.entries[0] = ['ok']
            const isValid = validator(entriesRelationData)
            expect(isValid).toEqual(false)
        })

        test('should return false for entries with too many arguments', () => {
            entriesRelationData.entries[0] = ['ok', 'test', 'banana', 'apple', 'pear', 'eggplant']
            const isValid = validator(entriesRelationData)
            expect(isValid).toEqual(false)
        })

        test('should return false for object entry which does not match the schema', () => {
            entriesRelationData.entries[0] = {
                prop: 'value'
            }
            const isValid = validator(entriesRelationData)
            expect(isValid).toEqual(false)
        })
    })

    describe('add entries block button', () => {
        test('should add empty entries block', () => {
            const components = wrapper.findAllComponents(EntriesRelationList)
            const parentComponent = components.at(0)
            const addEntriesBlockButton = parentComponent.find('.add-entries-block-button')
            addEntriesBlockButton.trigger('click')
            const childComponents = parentComponent.findAllComponents(EntriesRelationList)
            expect(childComponents.length).toEqual(3)
        })

        test('should copy entries data from parent to new entries block child', () => {
            const wantedEntryData = wrapper.vm.ld.cloneDeep(entryData1.entries)
            const components = wrapper.findAllComponents(EntriesRelationList)
            const parentComponent = components.at(1)
            const addEntriesBlockButton = parentComponent.find('.add-entries-block-button')
            addEntriesBlockButton.trigger('click')
            const childComponent = parentComponent.findComponent(EntriesRelationList)
            const categories = childComponent.findAll('.entry-category')
            const values = childComponent.findAll('.entry-value')
            expect(categories.at(0).text().toLowerCase()).toContain(wantedEntryData[0][0].toLowerCase())
            expect(values.at(0).text().toLowerCase()).toContain(wantedEntryData[0][1].toLowerCase())
            expect(categories.at(1).text().toLowerCase()).toContain(wantedEntryData[1][0].toLowerCase())
            expect(values.at(1).text().toLowerCase()).toContain(wantedEntryData[1][1].toLowerCase())
            expect(entriesRelationData.entries[0].entries[0].entries).toEqual(wantedEntryData)
        })

        test('should copy relation status from parent to new entries block child', () => {
            const components = wrapper.findAllComponents(EntriesRelationList)
            const parentComponent = components.at(1)
            const addEntriesBlockButton = parentComponent.find('.add-entries-block-button')
            addEntriesBlockButton.trigger('click')
            expect(entriesRelationData.entries[0].entries[0].relation.toLowerCase()).toEqual('or')
        })

        test('should not have the option to add component if not editable', () => {
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    relationList: entriesRelationData,
                    editable: false
                }
            })
            const components = wrapper.findAllComponents(EntriesRelationList)
            const componentToRemove = components.at(0)
            const addEntriesBlockButton = componentToRemove.find('.add-entries-block-button')
            expect(addEntriesBlockButton.element).toBeUndefined()
        })
    })

    describe('remove entries block button', () => {
        test('should remove entries block', async () => {
            let components = wrapper.findAllComponents(EntriesRelationList)
            const componentToRemove = components.at(1)
            const removeEntriesBlockButton = componentToRemove.find('.remove-entries-block-button')
            removeEntriesBlockButton.trigger('click')
            await Vue.nextTick()
            components = wrapper.findAllComponents(EntriesRelationList)
            expect(components.length).toEqual(2)
        })

        test('should not have the option to remove top level component', () => {
            entriesRelationData.entries = []
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    relationList: entriesRelationData,
                    editable: true
                }
            })
            const components = wrapper.findAllComponents(EntriesRelationList)
            const componentToRemove = components.at(0)
            const removeEntriesBlockButton = componentToRemove.find('.remove-entries-block-button')
            expect(removeEntriesBlockButton.element).toBeUndefined()
        })

        test('should not have the option to remove component if not editable', () => {
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    relationList: entriesRelationData,
                    editable: false
                }
            })
            const components = wrapper.findAllComponents(EntriesRelationList)
            const componentToRemove = components.at(1)
            const removeEntriesBlockButton = componentToRemove.find('.remove-entries-block-button')
            expect(removeEntriesBlockButton.element).toBeUndefined()
        })
    })

    describe('add entry button', () => {
        test('should open new entry table', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            expect(newEntryTable.element).toBeDefined()
        })

        test('should add new entry from input when confirm button is clicked', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            const newEntryTextarea = newEntryTable.find('.new-entry-textarea')
            newEntryTextarea.setValue('1.2.3.4#annotation')
            const confirmAddEntryButton = component.find('.confirm-add-entry-button')
            confirmAddEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(3)
            expect(entryData1.entries[0]).toEqual(['ip', '1.2.3.4', 'annotation'])
        })

        test('should add multiple new entries from input when confirm button is clicked', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            const newEntryTextarea = newEntryTable.find('.new-entry-textarea')
            newEntryTextarea.setValue('1.2.3.4#annotation\n127.0.0.1#localhost')
            const confirmAddEntryButton = component.find('.confirm-add-entry-button')
            confirmAddEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(4)
            expect(entryData1.entries[0]).toEqual(['ip', '127.0.0.1', 'localhost'])
            expect(entryData1.entries[1]).toEqual(['ip', '1.2.3.4', 'annotation'])
        })

        test('should add new entries from multi-line input when confirm button is clicked', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            const typeSelection = newEntryTable.find('.new-entry-type-selection')
            typeSelection.trigger('click')
            const options = typeSelection.findAll('option')
            options.at(7).element.selected = true
            typeSelection.trigger('change')
            await Vue.nextTick()
            const newEntryTextarea = newEntryTable.find('.new-entry-textarea')
            newEntryTextarea.setValue('something\nright\nhere')
            const confirmAddEntryButton = component.find('.confirm-add-entry-button')
            confirmAddEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(3)
            expect(entryData1.entries[0]).toEqual(['headers', ['something', 'right'], 'here'])
        })

        test('should not add new entries from multi-line input when confirm button is clicked if has too few lines', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            const typeSelection = newEntryTable.find('.new-entry-type-selection')
            typeSelection.trigger('click')
            const options = typeSelection.findAll('option')
            options.at(7).element.selected = true
            typeSelection.trigger('change')
            await Vue.nextTick()
            const newEntryTextarea = newEntryTable.find('.new-entry-textarea')
            newEntryTextarea.setValue('something')
            const confirmAddEntryButton = component.find('.confirm-add-entry-button')
            confirmAddEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(2)
        })

        test('should not add new entries from multi-line input when confirm button is clicked if has too many lines', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            const typeSelection = newEntryTable.find('.new-entry-type-selection')
            typeSelection.trigger('click')
            const options = typeSelection.findAll('option')
            options.at(7).element.selected = true
            typeSelection.trigger('change')
            await Vue.nextTick()
            const newEntryTextarea = newEntryTable.find('.new-entry-textarea')
            newEntryTextarea.setValue('something\n1\n2\n3\n4\n5\n6')
            const confirmAddEntryButton = component.find('.confirm-add-entry-button')
            confirmAddEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(2)
        })

        test('should not show new entry button if not editable', () => {
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    relationList: entriesRelationData,
                    editable: false
                }
            })
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const addEntryButton = component.find('.add-entry-button')
            expect(addEntryButton.element).toBeUndefined()
        })
    })

    describe('remove entry button', () => {
        test('should remove entry', async () => {
            const component = wrapper.findAllComponents(EntriesRelationList).at(1)
            const removeEntryButton = component.find('.remove-entry-button')
            removeEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(1)
        })
    })
})
