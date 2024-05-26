test_that("site_down", {
  expect_error(site_down("notarealwebsite"),
               "The website notarealwebsite is not available")
  expect_error(site_down("notarealwebsite", "No %s"),
               "No notarealwebsite")

  expect_true(site_down("notarealwebsite", error = FALSE))

  skip_if_offline("localhost")

  expect_false(site_down("localhost"))
  expect_false(site_down("http://localhost"))
  expect_false(site_down("https://localhost"))
  expect_false(site_down("localhost/otherstuff"))
})
