capture.output({ ## suppresses printing of console output when running test()

  test_that("fixesSLids returns expected columns in expected order", {

    myH1RawObject <- H1Example

    # Only use a subset of the test data
    myH1RawObject <- filterRDBESDataObject(myH1RawObject, c("DEstratumName"), c("DE_stratum1_H1"), killOrphans = TRUE)

	expectedCols<-c("SLid", "SLtaxaId", "SLrecType", "SLcou", "SLinst", "SLspeclistName","SLyear","SLcatchFrac", "SLcommTaxon","SLsppCode")
	expect_equal(colnames(fixSLids(myH1RawObject)$SL), expectedCols)
})

  test_that("SLid returned by fixesSLids exists in SS", {

    myH1RawObject <- H1Example
    #see https://github.com/r-lib/testthat/issues/1346
	expect_true(all(unique(myH1RawObject$SS$SLid) %in% unique(fixSLids(myH1RawObject)$SL$SLid)))

})

  test_that("SLtaxaId returned by fixesSLids similar to original SL$SLid", {

    myH1RawObject <- H1Example
	expect_equal(sort(fixSLids(myH1RawObject)$SL$SLtaxaId), sort(myH1RawObject$SL$SLid))

})


  test_that("fixesSLids issues message if SLtaxaId already there", {

    myH1RawObject <- H1Example
	myH1RawObject$SL$SLtaxaId<-NA
	expect_error(fixSLids(myH1RawObject, strict=F))

  })

})

