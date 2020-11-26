import EntriesRelationList from '@/components/EntriesRelationList'
import {describe, test, expect, beforeEach, jest, afterEach} from '@jest/globals'
import {mount} from '@vue/test-utils'
import Vue from 'vue'

describe('EntriesRelationList.vue', () => {
    let wrapper
    let ruleData
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
        ruleData = {
            relation: 'and',
            sections: [
                entryData1,
                entryData2
            ]
        }
        wrapper = mount(EntriesRelationList, {
            propsData: {
                rule: ruleData,
                editable: true
            }
        })
    })
    afterEach(() => {
        jest.clearAllMocks()
    })

    test('should have a single table rendered for each entries list', () => {
        const tables = wrapper.findAll('.entries-table')
        expect(tables.length).toEqual(2)
    })

    test('should display correct data from prop to view', () => {
        const wantedEntryData = wrapper.vm.ld.cloneDeep(entryData1.entries)
        const component = wrapper.findComponent(EntriesRelationList)
        const categories = component.findAll('.entry-category')
        const values = component.findAll('.entry-value')
        expect(categories.at(0).text().toLowerCase()).toContain(wantedEntryData[0][0].toLowerCase())
        expect(values.at(0).text().toLowerCase()).toContain(wantedEntryData[0][1].toLowerCase())
        expect(categories.at(1).text().toLowerCase()).toContain(wantedEntryData[1][0].toLowerCase())
        expect(values.at(1).text().toLowerCase()).toContain(wantedEntryData[1][1].toLowerCase())
        expect(ruleData.sections[0].entries).toEqual(wantedEntryData)
    })

    test('should display correct data from prop to view if data changed', async() => {
        const wantedEntryData = ['ip', '1.2.3.4']
        ruleData.sections[0].entries = [wantedEntryData]
        await Vue.nextTick()
        const component = wrapper.findComponent(EntriesRelationList)
        const categories = component.findAll('.entry-category')
        const values = component.findAll('.entry-value')
        expect(categories.at(0).text().toLowerCase()).toContain(wantedEntryData[0].toLowerCase())
        expect(values.at(0).text().toLowerCase()).toContain(wantedEntryData[1].toLowerCase())
    })

    test('should not break if not given a prop', () => {
        wrapper = mount(EntriesRelationList)
        const component = wrapper.findComponent(EntriesRelationList)
        expect(component).toBeTruthy()
    })

    test('should not break if data changes to invalid data', async() => {
        entryData1 = {}
        await Vue.nextTick()
        const component = wrapper.findComponent(EntriesRelationList)
        expect(component).toBeTruthy()
    })

    describe('large data pagination', () => {
        let checkedComponent
        let checkedTable
        beforeEach(() => {
            entryData1 = {
                relation: 'and',
                entries: [
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
            }
            ruleData = {
                relation: 'and',
                sections: [
                    entryData1
                ]
            }
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    rule: ruleData,
                    editable: true
                }
            })
            checkedComponent = wrapper.findComponent(EntriesRelationList)
            checkedTable = checkedComponent.findAll('.entries-table').at(0)
        })

        test('should show 20 entries per page', () => {
            const entryRows = checkedTable.findAll('.entry-row')
            expect(entryRows.length).toEqual(20)
        })

        test('should correctly render next page when next page button is clicked', async () => {
            const nextPageButton = checkedTable.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            const entryRows = checkedTable.findAll('.entry-row')
            expect(entryRows.length).toEqual(10)
        })

        test('should have next page button disabled if currently in last page', async () => {
            const nextPageButton = checkedTable.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            expect(nextPageButton.attributes('disabled')).toBeTruthy()
        })

        test('should correctly render prev page when next prev button is clicked', async () => {
            const nextPageButton = checkedTable.find('.pagination-next')
            nextPageButton.trigger('click')
            await Vue.nextTick()
            const prevPageButton = checkedTable.find('.pagination-previous')
            prevPageButton.trigger('click')
            await Vue.nextTick()
            const entryRows = checkedTable.findAll('.entry-row')
            expect(entryRows.length).toEqual(20)
        })

        test('should have prev page button disabled if currently in first page', async () => {
            const prevPageButton = checkedTable.find('.pagination-previous')
            expect(prevPageButton.attributes('disabled')).toBeTruthy()
        })
    })

    describe('rule prop validator', () => {
        let validator
        beforeEach(() => {
            validator = EntriesRelationList.props.rule.validator
        })

        test('should return true for data in the correct schema', () => {
            const isValid = validator(ruleData)
            expect(isValid).toEqual(true)
        })

        test('should return false for relation not `or` or `and`', () => {
            ruleData.relation = 'unknown value'
            const isValid = validator(ruleData)
            expect(isValid).toEqual(false)
        })

        test('should return false for entries with too few arguments', () => {
            ruleData.sections[0].entries[0] = ['ok']
            const isValid = validator(ruleData)
            expect(isValid).toEqual(false)
        })

        test('should return false for entries with too many arguments', () => {
            ruleData.sections[0].entries[0] = ['ok', 'test', 'banana', 'apple', 'pear', 'eggplant']
            const isValid = validator(ruleData)
            expect(isValid).toEqual(false)
        })

        test('should return false for object entry which does not match the schema', () => {
            ruleData.sections[0].entries[0] = {
                prop: 'value'
            }
            const isValid = validator(ruleData)
            expect(isValid).toEqual(false)
        })
    })

    describe('add entries block button', () => {
        test('should add empty entries block', () => {
            const component = wrapper.findComponent(EntriesRelationList)
            const addEntriesBlockButton = component.find('.add-entries-block-button')
            addEntriesBlockButton.trigger('click')
            const tables = component.findAll('.entries-table')
            expect(tables.length).toEqual(2)
        })

        test('should not have the option to add component if not editable', () => {
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    rule: ruleData,
                    editable: false
                }
            })
            const component = wrapper.findComponent(EntriesRelationList)
            const addEntriesBlockButton = component.find('.add-entries-block-button')
            expect(addEntriesBlockButton.element).toBeUndefined()
        })
    })

    describe('remove entries block button', () => {
        test('should remove entries block', async () => {
            const component = wrapper.findComponent(EntriesRelationList)
            const removeEntriesBlockButton = component.find('.remove-entries-block-button')
            removeEntriesBlockButton.trigger('click')
            await Vue.nextTick()
            const tables = wrapper.findAll('.entries-table')
            expect(tables.length).toEqual(1)
        })

        test('should not have the option to remove top level component', () => {
            ruleData.sections = []
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    rule: ruleData,
                    editable: true
                }
            })
            const component = wrapper.findComponent(EntriesRelationList)
            const removeEntriesBlockButton = component.find('.remove-entries-block-button')
            expect(removeEntriesBlockButton.element).toBeUndefined()
        })

        test('should not have the option to remove component if not editable', () => {
            wrapper = mount(EntriesRelationList, {
                propsData: {
                    rule: ruleData,
                    editable: false
                }
            })
            const component = wrapper.findComponent(EntriesRelationList)
            const removeEntriesBlockButton = component.find('.remove-entries-block-button')
            expect(removeEntriesBlockButton.element).toBeUndefined()
        })
    })

    describe('add entry button', () => {
        test('should open new entry table', async () => {
            const component = wrapper.findComponent(EntriesRelationList)
            const addEntryButton = component.find('.add-entry-button')
            addEntryButton.trigger('click')
            await Vue.nextTick()
            const newEntryTable = component.find('.new-entry-table')
            expect(newEntryTable.element).toBeDefined()
        })

        test('should add new entry from input when confirm button is clicked', async () => {
            const component = wrapper.findComponent(EntriesRelationList)
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
            const component = wrapper.findComponent(EntriesRelationList)
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
            const component = wrapper.findComponent(EntriesRelationList)
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
            const component = wrapper.findComponent(EntriesRelationList)
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
            const component = wrapper.findComponent(EntriesRelationList)
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
                    rule: ruleData,
                    editable: false
                }
            })
            const component = wrapper.findComponent(EntriesRelationList)
            const addEntryButton = component.find('.add-entry-button')
            expect(addEntryButton.element).toBeUndefined()
        })
    })

    describe('remove entry button', () => {
        test('should remove entry', async () => {
            const component = wrapper.findComponent(EntriesRelationList)
            const removeEntryButton = component.find('.remove-entry-button')
            removeEntryButton.trigger('click')
            await Vue.nextTick()
            expect(entryData1.entries.length).toEqual(1)
        })
    })
})
