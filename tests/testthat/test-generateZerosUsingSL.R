capture.output({  ## suppresses printing of console output when running test()

test_that("generateZerosUsingSL creates rows for SLcou*SLinst*SLspeclistName*SLyear*SLcatchFrac*SLcommTaxon", {


# dev notes
# tests should be partioned into several test_that sections


		#myH1DataObject1[c("SL","SS", "SA")]
		#generateZerosUsingSL(myH1DataObject1)[c("SL","SS", "SA")]


# create test data from download [to be used in different tests]

	myH1DataObject <- RDBEScore::createRDBESDataObject("./h1_v_1_19_26/ZW_1965_WGRDBES-EST_TEST_1.zip")

	# Only use a subset of the test data
	myH1DataObject0 <- filterRDBESDataObject(myH1DataObject,c("DEstratumName"),c("Pckg_survey_apistrat_H1"))
	myH1DataObject0 <- filterRDBESDataObject(myH1DataObject0,c("SLspeclistName"),c("WGRDBES-EST_TEST_1_Pckg_survey_apistrat_H1"))
	myH1DataObject0 <- findAndKillOrphans(myH1DataObject0)

	validateRDBESDataObject(myH1DataObject0, checkDataTypes = TRUE)

	df1 <- data.frame('31831','SL','ZW','4484',myH1DataObject0[["SL"]]$SLspeclistName,'1965','Dis','107254','107254')


	colnames(df1) <- names(myH1DataObject0[["SL"]])
	myH1DataObject0[["SL"]] <- rbind(myH1DataObject0[["SL"]],df1)
	myH1DataObject0[["SL"]]$SLid <- as.integer(myH1DataObject0[["SL"]]$SLid)
	myH1DataObject0[["SL"]]$SLyear <- as.integer(myH1DataObject0[["SL"]]$SLyear)
	myH1DataObject0[["SL"]]$SLcommTaxon <- as.integer(myH1DataObject0[["SL"]]$SLcommTaxon)
	myH1DataObject0[["SL"]]$SLsppCode <- as.integer(myH1DataObject0[["SL"]]$SLsppCode)
	# add an additional species list - could be many in the SL download
	myH1DataObject0[["SL"]]<-rbind(myH1DataObject0[["SL"]], myH1DataObject[["SL"]][1,])

	# ensure key is set on SL
	setkey(myH1DataObject0[["SL"]], SLid)

	myH1DataObject0[["SS"]]<-rbind(myH1DataObject0[["SS"]][1,],myH1DataObject0[["SS"]][1,])
	myH1DataObject0[["SS"]]$SScatchFra[2]<-"Dis"
	myH1DataObject0[["SS"]]$SSid[2]<-myH1DataObject0[["SS"]]$SSid[1]+1
	myH1DataObject0[["SS"]]$SLid[2]<-as.integer(31831)
	myH1DataObject0[["SS"]]$SSid<-as.integer(myH1DataObject0[["SS"]]$SSid)
	myH1DataObject0[["SS"]]$SSuseCalcZero<-'Y'
	# ensure key is set on SS
	setkey(myH1DataObject0[["SS"]], SSid)

	myH1DataObject1 <- filterRDBESDataObject(myH1DataObject0, c("SAid"), c(572813), killOrphans = TRUE)
	validateRDBESDataObject(myH1DataObject0, checkDataTypes = TRUE)
	validateRDBESDataObject(myH1DataObject1, checkDataTypes = TRUE)

# species*catchFrac in SL and not in SA: expected behavior -> generate a 0 row in SA
# also tests creation of species list when SS present and no SA (e.g., 0 discards)

	  # check generateZerosUsingSL is creating missing row in SA
		myTest3 <- generateZerosUsingSL(myH1DataObject1)

	  # create aux id_table [Nuno's function] and tmpKey to use in test
		aux<-createTableOfRDBESIds(x = myTest3, addSAseqNums=FALSE)

	# will be unequal is species lists not applicable to samples not correctly handled
	expect_equal(nrow(myTest3$SA),length(myTest3$SS$SLid[match(aux$SSid[match(myTest3$SS$SSid,aux$SSid)], myTest3$SS$SSid)]))

		myTest3$SA$SLid <- myTest3$SS$SLid[match(aux$SSid[match(myTest3$SS$SSid,aux$SSid)], myTest3$SS$SSid)]
		myTest3$SL <- myTest3$SL[myTest3$SL$SLid %in% myTest3$SA$SLid, ]

	#run tests
	# all species in species list are now present in SA
		expect_equal(all(paste0(myTest3$SL$SLid, myTest3$SL$SLcommTaxon) %in% paste0(myTest3$SA$SLid, myTest3$SA$SAspeCode)),TRUE)
	# right number of rows generated
		expect_equal(nrow(myTest3$SA),2)
	# adds 1 more species to SL to test
		myH1DataObject2<-myH1DataObject1
		myH1DataObject2$SL<-rbind(myH1DataObject2$SL[1,],myH1DataObject2$SL[1,],myH1DataObject2$SL)
		myH1DataObject2$SL$SLid[1]<-31830 # dummy
		myH1DataObject2$SL$SLid[2]<-31829 # dummy
		myH1DataObject2$SL$SLcommTaxon[1:2]<-126437 # dummy
		myH1DataObject2$SL$SLcatchFrac[1]<-"Lan" # dummy
		myH1DataObject2$SL$SLsppCode[1:2]<-126437 # dummy
		setkey(myH1DataObject2[["SL"]], SLid)
		expect_equal(nrow(generateZerosUsingSL(myH1DataObject2)$SA),4)

	# no change if SSuseCalcZero<-'N'
		myH1DataObject2<-myH1DataObject1
		myH1DataObject2[["SS"]]$SSuseCalcZero<-'N'
		expect_equal(generateZerosUsingSL(myH1DataObject2),myH1DataObject2)
	#

# species*catchFrac in SL and in SA: expected behavior -> do not generate a 0 row in SA

	myH1DataObject2<-myH1DataObject1
	myH1DataObject2[["SS"]]<-myH1DataObject2[["SS"]][1,]
	myH1DataObject2<-filterRDBESDataObject(myH1DataObject2, c("SLid"), myH1DataObject2[["SS"]]$SLid, killOrphans = TRUE, verbose = TRUE)

	validateRDBESDataObject(myH1DataObject2, checkDataTypes = TRUE)

	result <- generateZerosUsingSL(myH1DataObject2)

	expect_equal(result, myH1DataObject2)

# if SScatchFra=="Catch" it should not generate 0s for any SA strata if spp present in list

	myH1DataObject2<-myH1DataObject1
		myH1DataObject2[["SS"]]<-myH1DataObject2[["SS"]][1,]
		myH1DataObject2<-filterRDBESDataObject(myH1DataObject2, c("SLid"), myH1DataObject2[["SS"]]$SLid, killOrphans = TRUE)
		myH1DataObject2[["SS"]]$SScatchFra<-"Catch"
		myH1DataObject2[["SL"]]$SLcatchFrac<-"Catch"
		# creates stratification in SA
		myH1DataObject2[["SA"]]<-rbind(myH1DataObject2[["SA"]][1,],myH1DataObject2[["SA"]][1,])
		myH1DataObject2[["SA"]]$SAstratification<-"Y"
		myH1DataObject2[["SA"]]$SAid[2]<-myH1DataObject2[["SA"]]$SAid[1]+1
		myH1DataObject2[["SA"]]$SAstratumName<-c("Landings","Discards")
		myH1DataObject2[["SA"]]$SAcatchCat<-c("Lan","Dis")	# this is just cosmetics
		setkey(myH1DataObject2[["SA"]], "SAid")

	validateRDBESDataObject(myH1DataObject2, checkDataTypes = TRUE)

	result <- generateZerosUsingSL(myH1DataObject2)

	expect_equal(result, myH1DataObject2)

# if SScatchFra=="Catch" it should generate 0s for all SA strata present if spp absent(but in SL)

	myH1DataObject2<-myH1DataObject1
		myH1DataObject2[["SS"]]<-myH1DataObject2[["SS"]][1,]
		myH1DataObject2<-filterRDBESDataObject(myH1DataObject2, c("SLid"), myH1DataObject2[["SS"]]$SLid, killOrphans = TRUE)
		myH1DataObject2[["SS"]]$SScatchFra<-"Catch"
		myH1DataObject2[["SL"]]$SLcatchFrac<-"Catch"

		# use in debug
		#myH1DataObject2[c(10,11,15)]

		# creates stratification in SA
		myH1DataObject2[["SA"]]<-rbind(myH1DataObject2[["SA"]][1,],myH1DataObject2[["SA"]][1,])
		myH1DataObject2[["SA"]]$SAstratification<-"Y"
		myH1DataObject2[["SA"]]$SAid[2]<-myH1DataObject2[["SA"]]$SAid[1]+1
		myH1DataObject2[["SA"]]$SAstratumName<-c("Landings","Discards")
		myH1DataObject2[["SA"]]$SAcatchCat<-c("Lan","Dis")	# this is just cosmetics
		setkey(myH1DataObject2[["SA"]], "SAid")
		# creates a spp not existing in SA
		myH1DataObject2[["SL"]]$SLcommTaxon<-as.integer(127007)

	validateRDBESDataObject(myH1DataObject2, checkDataTypes = TRUE)

	result <- generateZerosUsingSL(myH1DataObject2)

	expect_equal(nrow(result$SA),4)

# issue error if >1 SAcatchCat OR SAsex OR SAlandCat in same SSid*SAstratumName
	# explanation:
		# in a normal situation these variables are filled in the new from the 1st row of SSid*SAstratumName
		# if it happens that there are >1 values in that SSid*SAstratumName this is not valid - an error is issued
	myH1DataObject2<-myH1DataObject0
	myH1DataObject2$SA$SSid[1]<-myH1DataObject2$SA$SSid[2]
	myH1DataObject2$SA$SAcatchCat[1]<-"Dis"
	expect_error(generateZerosUsingSL(myH1DataObject2))

	myH1DataObject2<-myH1DataObject0
	myH1DataObject2$SA$SSid[1]<-myH1DataObject2$SA$SSid[2]
	myH1DataObject2$SA$SAsex[1]<-"F"
	expect_error(generateZerosUsingSL(myH1DataObject2))

	myH1DataObject2<-myH1DataObject0
	myH1DataObject2$SA$SSid[1]<-myH1DataObject2$SA$SSid[2]
	myH1DataObject2$SA$SAlandCat[1]<-"HuC"
	expect_error(generateZerosUsingSL(myH1DataObject2))


})

}) ## end capture.output


