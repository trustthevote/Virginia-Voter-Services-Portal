class window.Registration
  constructor: (residence) ->
    @residence  = ko.observable(residence)
    @overseas   = ko.computed => @residence() == 'outside'
    @domestic   = ko.computed => !@overseas()

    @initEligibilityFields()
    @initIdentityFields()
    @initAddressFields()
    @initOptionsFields()
    @initSummaryFields()
    @initOathFields()

  initEligibilityFields: ->
    @citizen                = ko.observable()
    @oldEnough              = ko.observable()
    @rightsWereRevoked      = ko.observable()
    @rightsRevokationReason = ko.observable()
    @rightsWereRestored     = ko.observable()
    @rightsRestoredOnMonth  = ko.observable()
    @rightsRestoredOnYear   = ko.observable()
    @rightsRestoredOnDay    = ko.observable()
    @rightsRestoredIn       = ko.observable()
    @rightsRestoredInText   = ko.computed => $("#registration_rights_restored_in option[value='#{@rightsRestoredIn()}']").text()
    @rightsRestoredOn       = ko.computed => pastDate(@rightsRestoredOnYear(), @rightsRestoredOnMonth(), @rightsRestoredOnDay())
    @dobYear                = ko.observable()
    @dobMonth               = ko.observable()
    @dobDay                 = ko.observable()
    @dob                    = ko.computed => pastDate(@dobYear(), @dobMonth(), @dobDay())
    @ssn                    = ko.observable()
    @noSSN                  = ko.observable()
    @dmvId                  = ko.observable()

    @isEligible = ko.computed =>
      @citizen() == '1' and
      @oldEnough() == '1' and
      !!@dob() and
      !@noSSN() and filled(@ssn()) and
      (@rightsWereRevoked() == '0' or
       filled(@rightsRevokationReason()) and @rightsWereRestored() == '1' and !!@rightsRestoredOn())

    @eligibilityErrors = ko.computed =>
      errors = []
      errors.push("Citizenship criteria") unless @citizen()
      errors.push("Age criteria") unless @oldEnough()

      rwr = @rightsWereRestored()
      filledRightsRestorationBlock = filled(rwr) and (rwr == '0' or @rightsRestoredOn())
      errors.push("Voting rights criteria") if !filled(@rightsWereRevoked()) or
        (@rightsWereRevoked() == '1' and
          (!filled(@rightsRevokationReason()) or
           !filledRightsRestorationBlock))

      errors.push('Date of birth') unless @dob()
      errors.push('Social Security #') if !ssn(@ssn()) and !@noSSN()
      errors

    @eligibilityInvalid = ko.computed => @eligibilityErrors().length > 0

  initIdentityFields: ->
    @firstName              = ko.observable()
    @middleName             = ko.observable()
    @lastName               = ko.observable()
    @suffix                 = ko.observable()
    @gender                 = ko.observable()
    @phone                  = ko.observable()
    @validPhone             = ko.computed => !filled(@phone()) or phone(@phone())
    @email                  = ko.observable()
    @validEmail             = ko.computed => !filled(@email()) or email(@email())

    @identityErrors = ko.computed =>
      errors = []
      errors.push('First name') unless filled(@firstName())
      errors.push('Last name') unless filled(@lastName())
      errors.push('Gender') unless filled(@gender())
      errors.push('Phone number') unless @validPhone()
      errors.push('Email address') unless @validEmail()
      errors

    @identityInvalid = ko.computed => @identityErrors().length > 0

  initAddressFields: ->
    @vvrIsRural             = ko.observable(false)
    @vvrRural               = ko.observable()
    @maIsSame               = ko.observable('1')
    @hasExistingReg         = ko.observable()
    @erIsRural              = ko.observable(false)
    @vvrStreetNumber        = ko.observable()
    @vvrStreetName          = ko.observable()
    @vvrStreetType          = ko.observable()
    @vvrApt                 = ko.observable()
    @vvrTown                = ko.observable()
    @vvrState               = ko.observable('VA')
    @vvrZip5                = ko.observable()
    @vvrZip4                = ko.observable()
    @vvrCountyOrCity        = ko.observable()
    @vvrCountySelected      = ko.computed => String(@vvrCountyOrCity()).match(/\s+county/i)
    @vvrOverseasRA          = ko.observable()
    @vvrUocavaResidenceUnavailableSinceDay = ko.observable()
    @vvrUocavaResidenceUnavailableSinceMonth = ko.observable()
    @vvrUocavaResidenceUnavailableSinceYear = ko.observable()
    @vvrUocavaResidenceUnavailableSince = ko.computed => pastDate(@vvrUocavaResidenceUnavailableSinceYear(), @vvrUocavaResidenceUnavailableSinceMonth(), @vvrUocavaResidenceUnavailableSinceDay())
    @maAddress1             = ko.observable()
    @maAddress2             = ko.observable()
    @maCity                 = ko.observable()
    @maState                = ko.observable()
    @maZip5                 = ko.observable()
    @maZip4                 = ko.observable()
    @mauType                = ko.observable('non-us')
    @mauAPOAddress1         = ko.observable()
    @mauAPOAddress2         = ko.observable()
    @mauAPO1                = ko.observable()
    @mauAPO2                = ko.observable()
    @mauAPOZip5             = ko.observable()
    @mauAddress             = ko.observable()
    @mauAddress2            = ko.observable()
    @mauCity                = ko.observable()
    @mauState               = ko.observable()
    @mauPostalCode          = ko.observable()
    @mauCountry             = ko.observable()
    @erStreetNumber         = ko.observable()
    @erStreetName           = ko.observable()
    @erStreetType           = ko.observable()
    @erApt                  = ko.observable()
    @erCity                 = ko.observable()
    @erState                = ko.observable()
    @erZip5                 = ko.observable()
    @erZip4                 = ko.observable()
    @erIsRural              = ko.observable()
    @erRural                = ko.observable()
    @erCancel               = ko.observable()

    @vvrCountyOrCity.subscribe (v) =>
      if v.match(/\s+city$/i)
        @vvrTown(v.replace(/\s+city$/i, ''))

    @vvrIsRural.subscribe (v) =>
      @maIsSame('0') if v

    @domesticMAFilled = ko.computed =>
      @maIsSame() == '1' or
      filled(@maAddress1()) and
      filled(@maCity()) and
      filled(@maState()) and
      zip5(@maZip5())

    @nonUSMAFilled = ko.computed =>
      filled(@mauAddress()) and
      filled(@mauCity()) and
      filled(@mauState()) and
      filled(@mauPostalCode()) and
      filled(@mauCountry())

    @overseasMAFilled = ko.computed =>
      if   @mauType() == 'apo'
      then filled(@mauAPO1()) and zip5(@mauAPOZip5())
      else @nonUSMAFilled()

    @addressesErrors = ko.computed =>
      errors = []

      residental =
        if   @vvrIsRural()
        then filled(@vvrRural())
        else filled(@vvrStreetNumber()) and
             filled(@vvrStreetName()) and
             filled(@vvrStreetType()) and
             (!@vvrCountySelected() or filled(@vvrTown())) and
             filled(@vvrState()) and
             zip5(@vvrZip5()) and
             filled(@vvrCountyOrCity())

      if @overseas()
        residental = residental and
          filled(@vvrOverseasRA()) and
          (@vvrOverseasRA() == '1' or @vvrUocavaResidenceUnavailableSince())
        mailing = @overseasMAFilled()
      else
        mailing = @domesticMAFilled()

      existing =
        @hasExistingReg() == '0' or
        @erCancel() and
        if   @erIsRural()
        then filled(@erRural())
        else filled(@erStreetNumber()) and
             filled(@erStreetName()) and
             filled(@erCity()) and
             filled(@erState()) and
             zip5(@erZip5())

      errors.push("Registration address") unless residental
      errors.push("Mailing address") unless mailing
      errors.push("Existing registration") unless existing
      errors

    @addressesInvalid = ko.computed => @addressesErrors().length > 0

  initOptionsFields: ->
    @party                  = ko.observable()
    @chooseParty            = ko.observable()
    @otherParty             = ko.observable()

    @caType                 = ko.observable()
    @isConfidentialAddress  = ko.observable()
    @caAddress1             = ko.observable()
    @caAddress2             = ko.observable()
    @caCity                 = ko.observable()
    @caZip5                 = ko.observable()
    @caZip4                 = ko.observable()

    @needsAssistance        = ko.observable()

    @requestingAbsentee     = ko.observable()
    @absenteeUntil          = ko.observable()
    @rabElection            = ko.observable()
    @rabElectionName        = ko.observable()
    @rabElectionDate        = ko.observable()
    @outsideType            = ko.observable()
    @needsServiceDetails    = ko.computed => @outsideType() && @outsideType().match(/MerchantMarine/)
    @serviceId              = ko.observable()
    @rank                   = ko.observable()

    @residence.subscribe (v) =>
      @requestingAbsentee(v == 'outside')

    @abReason               = ko.observable()
    @abField1               = ko.observable()
    @abField2               = ko.observable()
    @abStreetNumber         = ko.observable()
    @abStreetName           = ko.observable()
    @abStreetType           = ko.observable()
    @abApt                  = ko.observable()
    @abCity                 = ko.observable()
    @abState                = ko.observable()
    @abZip5                 = ko.observable()
    @abZip4                 = ko.observable()
    @abCountry              = ko.observable()
    @abTime1Hour            = ko.observable()
    @abTime1Minute          = ko.observable()
    @abTime2Hour            = ko.observable()
    @abTime2Minute          = ko.observable()

    @abAddressRequired = ko.computed =>
      r = @abReason()
      r == '1A' or
      r == '1B' or
      r == '1E' or
      r == '3A' or r == '3B'

    @abField1Required = ko.computed =>
      r = @abReason()
      r == '1A' or
      r == '1B' or
      r == '1C' or
      r == '1D' or
      r == '1E' or
      r == '2A' or
      r == '2B' or
      r == '3A' or r == '3B' or
      r == '5A' or
      r == '8A'

    @abField2Required = ko.computed =>
      r = @abReason()
      r == '2B' or
      r == '5A'

    @abTimeRangeRequired = ko.computed =>
      @abReason() == '1E'

    @abPartyLookupRequired = ko.computed =>
      @abReason() == '8A'

    @abField1Label = ko.computed =>
      r = @abReason()
      if r == '1A' or r == '1B'
        "Name of school"
      else if r == '1C' or r == '1E'
        "Name of employer or businesss"
      else if r == '1D'
        "Place of travel<br/>VA county/city, state or country"
      else if r == '2A' or r == '2B'
        "Nature of disability or illness"
      else if r == '3A' or r == '3B'
        "Place of confinement"
      else if r == '5A'
        "Religion"
      else if r == '8A'
        "Designated candidate party"

    @abField2Label = ko.computed =>
      r = @abReason()
      if r == '2B'
        "Name of family member"
      else if r == '5A'
        "Nature of obligation"

    @absenteeUntilFormatted = ko.computed =>
      au = @absenteeUntil()
      if !au or au.match(/^\s*$/)
        ""
      else
        moment(au).format("MMM D, YYYY")

    @beOfficial = ko.observable()

    @overseas.subscribe (v) =>
      setTimeout((=> @requestingAbsentee(true)), 0) if v

    @optionsErrors = ko.computed =>
      errors = []
      if @chooseParty()
        if !filled(@party()) || (@party() == 'other' and !filled(@otherParty()))
          errors.push("Party preference")

      if @isConfidentialAddress()
        if !filled(@caType())
          errors.push("Address confidentiality reason")
        else
          if !filled(@caAddress1()) || !filled(@caCity()) || !zip5(@caZip5())
            errors.push("Protected voter mailing address")

      if @requestingAbsentee()
        if @overseas()
          errors.push("Absense type") unless filled(@outsideType())
          errors.push("Service details") if @needsServiceDetails() and (!filled(@serviceId()) || !filled(@rank()))
        else
          if !filled(@rabElection()) or (@rabElection() == 'other' and (!filled(@rabElectionName()) or !filled(@rabElectionDate())))
            errors.push("Election details")

          if !filled(@abReason())
            errors.push("Absence reason")

          if @abAddressRequired() and
            (!filled(@abStreetNumber()) or
            !filled(@abStreetName()) or
            !filled(@abCity()) or
            !filled(@abState()) or
            !zip5(@abZip5()) or
            !filled(@abCountry()))
              errors.push("Address in supporting information")

          if @abTimeRangeRequired() and
            (!filled(@abTime1Hour()) or
            !filled(@abTime1Minute()) or
            !filled(@abTime2Hour()) or
            !filled(@abTime2Minute()))
              errors.push("Time range in supporting information")

          if @abField1Required() and
            !filled(@abField1())
              errors.push(@abField1Label())

          if @abField2Required() and
            !filled(@abField2())
              errors.push(@abField2Label())

      errors

    @optionsInvalid = ko.computed => @optionsErrors().length > 0

  setAbsenteeUntil: (val) ->
    @absenteeUntil(val)
    $("#registration_absentee_until").val(val)

  initAbsenteeUntilSlider: ->
    return if @abstenteeUntilSlider
    rau = $("#registration_absentee_until").val()
    @setAbsenteeUntil(rau)

    days = Math.floor((moment(rau) - moment()) / 86400000)
    @absenteeUntilSlider = $("#absentee_until")
    @absenteeUntilSlider.slider(min: 45, max: 365, value: days, slide: @onAbsenteeUntilSlide)

  onAbsenteeUntilSlide: (e, ui) =>
    val = moment().add('days', ui.value).format("YYYY-MM-DD")
    @setAbsenteeUntil(val)
    true

  initSummaryFields: ->
    @summaryFullName = ko.computed =>
      valueOrUnspecified(join([ @firstName(), @middleName(), @lastName(), @suffix() ], ' '))

    @summaryCitizen   = ko.computed => yesNo(@citizen())
    @summaryOldEnough = ko.computed => yesNo(@oldEnough())
    @summaryGender    = ko.computed => valueOrUnspecified(@gender())

    @summaryVotingRights = ko.computed =>
      if @rightsWereRevoked() == '0'
        "Haven't been convicted of a felony or adjudicated mentally incapacitated"
      else
        lines = [ ]
        if @rightsRevokationReason() == 'felony'
          lines.push "Have been convicted of a felony"
        else
          lines.push "Have been adjudicated mentally incapacitated"

        if @rightsWereRestored() == '0'
          lines.push "Voting rights were not restored"
        else
          lines.push "Voting rights were restored in #{@rightsRestoredInText()} on #{moment(@rightsRestoredOn()).format("MMMM Do, YYYY")}"

        lines.join "<br/>"
    @summarySSN = ko.computed =>
      if @noSSN() || !filled(@ssn())
        "No Social Security Number"
      else
        @ssn()
    @summaryDMVID = ko.computed =>
      if !filled(@dmvId())
        "No DMV ID"
      else
        @dmvId()
    @summaryDOB = ko.computed =>
      if filled(@dobMonth()) && filled(@dobDay()) && filled(@dobYear())
        moment([ @dobYear(), parseInt(@dobMonth()) - 1, @dobDay() ]).format("MMMM D, YYYY")
      else
        "Unspecified"

    @summaryRegistrationAddress = ko.computed =>
      if @vvrIsRural()
        @vvrRural()
      else
        join([ @vvrStreetNumber(), @vvrStreetName(), @vvrStreetType(), (if filled(@vvrApt()) then "##{@vvrApt()}" else null) ], ' ') + "<br/>" +
        join([ @vvrTown(), join([ @vvrState(), join([ @vvrZip5(), @vvrZip4() ], '-') ], ' ') ], ', ')

    @summaryOverseasMailingAddress = ko.computed =>
      if @mauType() == 'apo'
        join([
          @mauAPOAddress1(),
          @mauAPOAddress2(),
          join([ @mauAPO1(), @mauAPO2(), @mauAPOZip5() ], ', ')
        ], "<br/>")
      else
        join([
          @mauAddress(),
          @mauAddress2(),
          join([ @mauCity(), join([ @mauState(), @mauPostalCode()], ' '), @mauCountry()], ', ')
        ], "<br/>")


    @summaryExistingRegistration = ko.computed =>
      if @hasExistingReg() == '0'
        false
      else
        lines = []
        if @erIsRural()
          lines.push @erRural()
        else
          lines.push join([ @erStreetNumber(), @erStreetName(), @erStreetType(), (if filled(@erApt()) then "##{@erApt()}" else null) ], ' ') + "<br/>" +
            join([ @erCity(), join([ @erState(), join([ @erZip5(), @erZip4() ], '-') ], ' ') ], ', ')
        if @erCancel()
          lines.push "Authorized cancelation"
         
        lines.join "<br/>"
    @summaryDomesticMailingAddress = ko.computed =>
      join([
        @maAddress1(),
        @maAddress2(),
        join([ @maCity(), join([ @maState(), join([ @maZip5(), @maZip4()], '-')], ' ')], ', ')
      ], "<br/>")

    @summaryMailingAddress = ko.computed =>
      if @overseas()
        @summaryOverseasMailingAddress()
      else
        if @maIsSame() == '1'
          @summaryRegistrationAddress()
        else
          @summaryDomesticMailingAddress()

    @summaryAddressConfidentiality = ko.computed =>
      if @isConfidentialAddress()
        "Code: #{@caType()}" + "<br/>" +
        join([
          @caAddress1(),
          @caAddress2(),
          join([ @caCity(), 'VA', join([ @caZip5(), @caZip4() ], '-') ], ' ')
        ], "<br/>")

    @summaryAbsenteeRequest = ko.computed =>
      lines = []

      if @rabElection() != 'other'
        election = @rabElection()
      else
        election = "#{@rabElectionName()} held on #{@rabElectionDate()}"
      lines.push "Applying to vote abstentee in #{election}"

      if filled(@abReason())
        lines.push "Reason: #{$("#registration_ab_reason option[value='#{@abReason()}']").text()}"

      if @abField1Required() and filled(@abField1())
        v = @abField1()
        if @abPartyLookupRequired()
          v = $("#registration_ab_field_1 option[value='#{v}']").text()
        lines.push "#{@abField1Label()}: #{v}"
      if @abField2Required() and filled(@abField2())
        lines.push "#{@abField2Label()}: #{@abField2()}"
      if @abTimeRangeRequired()
        h1 = @abTime1Hour()
        m1 = @abTime1Minute()
        h2 = @abTime2Hour()
        m2 = @abTime2Minute()
        lines.push "Time: #{time(h1, m1)} - #{time(h2, m2)}"
      if @abAddressRequired()
        lines.push join([ @abStreetNumber(), @abStreetName(), @abStreetType(), (if filled(@abApt()) then "##{@abApt()}" else null) ], ' ') + "<br/>" +
          join([ @abCity(), join([ @abState(), join([ @abZip5(), @abZip4() ], '-'), @abCountry() ], ' ') ], ', ')
      lines.join "<br/>"

    @showingPartySummary = ko.computed =>
      @requestingAbsentee() and @overseas() and @summaryParty()

    @summaryParty = ko.computed =>
      if @chooseParty()
        if @party() == 'other'
          @otherParty()
        else
          @party()
      else
        null

    @summaryElection = ko.computed =>
      if @rabElection() == 'other'
        "#{@rabElectionName()} on #{@rabElectionDate()}"
      else
        v = @rabElection()
        $("#registration_rab_election option[value='#{v}']").text()

  initOathFields: ->
    @infoCorrect  = ko.observable()
    @privacyAgree = ko.observable()

    @oathErrors = ko.computed =>
      errors = []
      errors.push("Confirm that information is correct") unless @infoCorrect()
      errors.push("Agree with privacy terms") unless @privacyAgree()
      errors.push("Social Security #") if !ssn(@ssn()) and !@noSSN()
      # errors.push('DMV ID#') if !@noSSN() and !isDmvId(@dmvId()) and !@noDmvId()
      errors

    @oathInvalid = ko.computed => @oathErrors().length > 0

