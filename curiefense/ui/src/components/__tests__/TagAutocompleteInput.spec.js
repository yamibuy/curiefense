import TagAutocompleteInput from '@/components/TagAutocompleteInput'
import {describe, test, expect, beforeEach, jest, afterEach} from '@jest/globals'
import {mount} from '@vue/test-utils'
import Vue from 'vue'

jest.mock('axios')
import axios from 'axios'

describe('TagAutocompleteInput.vue', () => {
    let wrapper
    let tagsData
    beforeEach(() => {
        tagsData = {
            data: {
                tags: [
                    'united-states',
                    'test-tag-1',
                    'test-tag-2',
                    'another-tag',
                    'devops',
                    'internal'
                ],
            },
        }
        axios.get.mockImplementation(() => Promise.resolve(tagsData))
        wrapper = mount(TagAutocompleteInput, {
            propsData: {
                autoFocus: true,
                clearInputAfterSelection: false
            }
        })
    })
    afterEach(() => {
        jest.clearAllMocks()
    })

    test('should have dropdown hidden on init', () => {
        expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeFalsy()
    })

    test('should have dropdown hidden after typing in input if empty', async () => {
        axios.get.mockImplementation(() => Promise.resolve({data: {}}))
        wrapper = mount(TagAutocompleteInput)
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        await Vue.nextTick()
        expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeFalsy()
    })

    test('should have dropdown displayed after typing in input', async () => {
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        await Vue.nextTick()
        expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeTruthy()
    })

    test('should emit changed tag when input changes', async () => {
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        await Vue.nextTick()
        expect(wrapper.emitted('tagChanged')).toBeTruthy()
        expect(wrapper.emitted('tagChanged')[0]).toEqual(['tag'])
    })

    test('should show correct filtered tags in dropdown ordered alphabetically', async () => {
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        await Vue.nextTick()
        const dropdownItems = wrapper.findAll('.dropdown-item')
        expect(dropdownItems.length).toEqual(3)
        expect(dropdownItems.at(0).text()).toEqual('another-tag')
        expect(dropdownItems.at(1).text()).toEqual('test-tag-1')
        expect(dropdownItems.at(2).text()).toEqual('test-tag-2')
    })

    test('should re-assign the input when prop changes', async () => {
        const newTag = 'another'
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        wrapper.setProps({initialTag: newTag})
        await Vue.nextTick()
        expect(input.element.value).toEqual(newTag)
    })

    test('should have dropdown hidden when prop changes', async () => {
        const newTag = 'another'
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        wrapper.setProps({initialTag: newTag})
        await Vue.nextTick()
        expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeFalsy()
    })

    test('should have dropdown hidden when prop changes to the same value', async () => {
        const tag = 'tag'
        const input = wrapper.find('.tag-input')
        input.element.value = tag
        input.trigger('input')
        wrapper.setProps({initialTag: tag})
        await Vue.nextTick()
        expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeTruthy()
    })

    test('should clear tag input when selected', async () => {
        wrapper.setProps({clearInputAfterSelection: true})
        const input = wrapper.find('.tag-input')
        input.element.value = 'tag'
        input.trigger('input')
        wrapper.setData({focusedSuggestionIndex: 2})
        input.trigger('keydown.enter')
        await Vue.nextTick()
        expect(input.element.value).toEqual('')
    })

    test('should send request to create new DB if missing on component creation', (done) => {
        axios.get.mockImplementation(() => Promise.reject())
        axios.post.mockImplementation((path) => {
            expect(path).toEqual('/conf/api/v1/db/system/')
            done()
            return Promise.resolve()
        })
        wrapper = mount(TagAutocompleteInput, {})
        Vue.nextTick()
    })

    test('should not send request to create new DB exists on component creation', async () => {
        const spy = jest.spyOn(axios, 'post')
        wrapper = mount(TagAutocompleteInput, {})
        await Vue.nextTick()
        expect(spy).not.toHaveBeenCalledWith('db/system/')
    })

    test('should send request to create new key in DB if missing on component creation', (done) => {
        axios.get.mockImplementation((path) => {
            if (path === '/conf/api/v1/db/') {
                return Promise.resolve(['system'])
            } else {
                return Promise.reject()
            }
        })
        axios.put.mockImplementationOnce((path) => {
            expect(path).toEqual('/conf/api/v1/db/system/k/autocomplete/')
            done()
            return Promise.resolve()
        })
        wrapper = mount(TagAutocompleteInput, {})
        Vue.nextTick()
    })

    test('should not send request to create new key in DB exists on component creation', async () => {
        const spy = jest.spyOn(axios, 'put')
        wrapper = mount(TagAutocompleteInput, {})
        await Vue.nextTick()
        expect(spy).not.toHaveBeenCalledWith('db/system/k/autocomplete')
    })

    test('should send request to add tag to DB if unknown tag selected', (done) => {
        const newTagName = 'tag-of-doom'
        const newTagsArray = [...tagsData.data.tags, ...[newTagName]]
        axios.put.mockImplementationOnce((path, data) => {
            expect(data).toEqual({tags: newTagsArray})
            done()
            return Promise.resolve()
        })
        const input = wrapper.find('.tag-input')
        input.element.value = newTagName
        input.trigger('input')
        input.trigger('keydown.enter')
        Vue.nextTick()
    })

    describe('keyboard control', () => {
        let input
        let dropdownItems
        beforeEach(async () => {
            input = wrapper.find('.tag-input')
            input.element.value = 'tag'
            input.trigger('input')
            dropdownItems = wrapper.findAll('.dropdown-item')
        })

        test('should focus on next item when down arrow is pressed', async () => {
            input.trigger('keydown.down')
            await Vue.nextTick()
            expect(dropdownItems.at(0).element.classList.contains('is-active')).toBeTruthy()
        })

        test('should focus on previous item when up arrow is pressed', async () => {
            wrapper.setData({focusedSuggestionIndex: 2})
            input.trigger('keydown.up')
            await Vue.nextTick()
            expect(dropdownItems.at(1).element.classList.contains('is-active')).toBeTruthy()
        })

        test('should not focus on next item when down arrow is pressed if focused on last element', async () => {
            wrapper.setData({focusedSuggestionIndex: 2})
            input.trigger('keydown.down')
            await Vue.nextTick()
            expect(dropdownItems.at(2).element.classList.contains('is-active')).toBeTruthy()
        })

        test('should not focus on any item when up arrow is pressed if focused on input', async () => {
            wrapper.setData({focusedSuggestionIndex: -1})
            input.trigger('keydown.up')
            await Vue.nextTick()
            expect(dropdownItems.at(0).element.classList.contains('is-active')).toBeFalsy()
            expect(dropdownItems.at(1).element.classList.contains('is-active')).toBeFalsy()
            expect(dropdownItems.at(2).element.classList.contains('is-active')).toBeFalsy()
        })

        test('should select focused tag when enter is pressed', async () => {
            wrapper.setData({focusedSuggestionIndex: 2})
            input.trigger('keydown.enter')
            await Vue.nextTick()
            expect(input.element.value).toEqual('test-tag-2')
        })

        test('should select input tag when enter is pressed and there is no focused tag', async () => {
            wrapper.setData({focusedSuggestionIndex: -1})
            input.element.value = 'test-tag-1'
            input.trigger('input')
            input.trigger('keydown.enter')
            await Vue.nextTick()
            expect(input.element.value).toEqual('test-tag-1')
        })

        test('should emit selected tag when enter is pressed', async () => {
            wrapper.setData({focusedSuggestionIndex: 2})
            input.trigger('keydown.enter')
            expect(wrapper.emitted('tagSubmitted')).toBeTruthy()
            expect(wrapper.emitted('tagSubmitted')[0]).toEqual(['test-tag-2'])
        })

        test('should select tag when clicked', async () => {
            dropdownItems.at(1).trigger('click')
            await Vue.nextTick()
            expect(input.element.value).toEqual('test-tag-1')
        })

        test('should emit selected tag when clicked', async () => {
            dropdownItems.at(1).trigger('click')
            expect(wrapper.emitted('tagSubmitted')).toBeTruthy()
            expect(wrapper.emitted('tagSubmitted')[0]).toEqual(['test-tag-1'])
        })

        test('should have dropdown hidden when esc is pressed', async () => {
            input.trigger('keydown.esc')
            await Vue.nextTick()
            expect(wrapper.find('.dropdown').element.classList.contains('is-active')).toBeFalsy()
        })
    })

    describe('multiple tags selection', () => {
        let input
        beforeEach(async () => {
            wrapper = mount(TagAutocompleteInput, {
                propsData: {
                    autoFocus: true,
                    selectionType: 'multiple'
                }
            })
            input = wrapper.find('.tag-input')
            input.element.value = 'devops tag'
            input.trigger('input')
        })

        test('should filter suggestion based on last word in input', async () => {
            const dropdownItems = wrapper.findAll('.dropdown-item')
            expect(dropdownItems.length).toEqual(3)
            expect(dropdownItems.at(0).text()).toEqual('another-tag')
            expect(dropdownItems.at(1).text()).toEqual('test-tag-1')
            expect(dropdownItems.at(2).text()).toEqual('test-tag-2')
        })

        test('should only change last word in input when selecting tag', async () => {
            wrapper.setData({focusedSuggestionIndex: 2})
            input.trigger('keydown.enter')
            await Vue.nextTick()
            expect(input.element.value).toEqual('devops test-tag-2')
        })
    })
})
