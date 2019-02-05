describe 'engage tab', () ->
  before ->
    cy.login()
    cy.unfollow("A")
    cy.clear_machine_cache()

  beforeEach ->
    cy.visit_bridge()

  specify 'follow button', () ->
    cy.contains("follow")
      .get('.follow-link').click()
    cy.contains("following")
    cy.contains("1 follower")
    cy.get(".follow-link").click()
    cy.contains("follow")
    cy.contains("0 follower")

  specify "advanced button", () ->
    cy.get("[data-cy=follow-advanced]")
      .click()

    cy.bridge().get(".title").should("contain", "follow")
    cy.get(".pointer-radio-list input").first().check()
    cy.get("#card_name_aselfjoe_adminfollow").check()
    cy.get("[data-cy=submit-overlay]").click().wait(5000)

    cy.bridge_sidebar().should("contain", "1 follower").and("contain", "following")
      .get('.follow-link').click()
    cy.unfollow("A")

  specify "all followed cards", () ->
    cy.el("follow-overview").click()
    cy.bridge().should("contain", "Follow").and("contain", "Ignore")

  specify "followers", () ->
    cy.get('.follow-link').click()
    cy.el("followers").click()
    cy.bridge()
      .should("contain", "followers")
      .and("contain", "Joe Admin")
    cy.get(".follow-link").click()
    cy.bridge()
      .should("contain", "followers")
      .and("not.contain", "Joe Admin")

  specify "discussion", () ->
    cy.get('#card_comment').type("yeah")
    cy.get(".comment-buttons > [type=submit]").click()
    cy.bridge_sidebar()
      .get(".RIGHT-discussion")
      .should("contain", "yeah")
      .and("contain", "Joe Admin")
