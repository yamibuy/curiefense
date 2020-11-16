import Utils from '@/assets/Utils'
import {describe, test, expect, beforeEach} from '@jest/globals'

describe('Utils.js', () => {

    describe('generateUniqueEntityName function', () => {
        let entities
        let initialName
        beforeEach(() => {
            initialName = 'entityName'
            entities = [initialName]
        })

        test('should generate name for new entity', async () => {
            const wantedName = `new entity`

            const actualName = Utils.generateUniqueEntityName(null, entities)
            expect(actualName).toEqual(wantedName)
        })

        test('should generate name for new entity with given divider', async () => {
            const wantedName = `new___entity`

            const actualName = Utils.generateUniqueEntityName(null, entities, false, '___')
            expect(actualName).toEqual(wantedName)
        })

        test('should generate name for copied entity with given divider', async () => {
            const wantedName = `copy__of__${initialName}`

            const actualName = Utils.generateUniqueEntityName(initialName, entities, true, '__')
            expect(actualName).toEqual(wantedName)
        })

        test('should generate name for copied entity', async () => {
            const wantedName = `copy of ${initialName}`

            const actualName = Utils.generateUniqueEntityName(initialName, entities, true)
            expect(actualName).toEqual(wantedName)
        })

        test('should generate name for copied entity if copy exists in list', async () => {
            const firstCopyName = `copy of ${initialName}`
            const wantedName = `copy of ${initialName}(2)`
            entities.push(firstCopyName)

            const actualName = Utils.generateUniqueEntityName(initialName, entities, true)
            expect(actualName).toEqual(wantedName)
        })

        test('should generate name for copied entity if copy exists in list X times', async () => {
            const firstCopyName = `copy of ${initialName}`
            const wantedName = `copy of ${initialName}(5)`
            entities.push(firstCopyName, `${firstCopyName}(2)`, `${firstCopyName}(3)`, `${firstCopyName}(4)`)

            const actualName = Utils.generateUniqueEntityName(initialName, entities, true)
            expect(actualName).toEqual(wantedName)
        })
    })

    describe('validateInput function', () => {
        let event
        let validator
        const validValidator = () => {
            return true
        }
        const invalidValidator = () => {
            return false
        }
        beforeEach(() => {
            event = {
                target: {
                    className: 'is-big is-bird is-yellow'
                },
                type: "input"
            }
        })

        test('should handle boolean validator', async () => {
            validator = false
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('has-text-danger')
            expect(event.target.className).toContain('has-background-danger-light')
        })

        test('should handle functional validator', async () => {
            validator = () => false
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('has-text-danger')
            expect(event.target.className).toContain('has-background-danger-light')
        })

        test('should pass event to functional validator', async () => {
            validator = (e) => {
                return e.type === 'click'
            }
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('has-text-danger')
            expect(event.target.className).toContain('has-background-danger-light')
        })

        test('should add classes to invalid input', async () => {
            validator = invalidValidator
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('has-text-danger')
            expect(event.target.className).toContain('has-background-danger-light')
        })

        test('should remove classes from valid input', async () => {
            validator = invalidValidator
            Utils.validateInput(event, validator)
            validator = validValidator
            Utils.validateInput(event, validator)
            expect(event.target.className).not.toContain('has-text-danger')
            expect(event.target.className).not.toContain('has-background-danger-light')
        })

        test('should not remove unrelated classes while validating', async () => {
            validator = validValidator
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('is-big')
            expect(event.target.className).toContain('is-bird')
            expect(event.target.className).toContain('is-yellow')
            validator = invalidValidator
            Utils.validateInput(event, validator)
            expect(event.target.className).toContain('is-big')
            expect(event.target.className).toContain('is-bird')
            expect(event.target.className).toContain('is-yellow')
        })
    })
})
