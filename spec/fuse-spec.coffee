Fuse = require '../lib/fuse'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Fuse", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('fuse')

  describe "when the fuse:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.fuse')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'fuse:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.fuse')).toExist()

        fuseElement = workspaceElement.querySelector('.fuse')
        expect(fuseElement).toExist()

        fusePanel = atom.workspace.panelForItem(fuseElement)
        expect(fusePanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'fuse:toggle'
        expect(fusePanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.fuse')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'fuse:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        fuseElement = workspaceElement.querySelector('.fuse')
        expect(fuseElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'fuse:toggle'
        expect(fuseElement).not.toBeVisible()
