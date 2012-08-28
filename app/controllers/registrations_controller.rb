class RegistrationsController < ApplicationController

  before_filter :requires_registration, except: [ :new, :create ]

  def new
    LogRecord.log('VoterRegistrationRequest', 'start')

    options = RegistrationRepository.pop_search_query(session)
    options.merge!(
      residence:            params[:residence],
      requesting_absentee:  params[:residence] == 'outside' ? '1' : '0')

    @registration = Registration.new(options)
    @registration.init_absentee_until
  end

  def create
    data = params[:registration]
    Converter.params_to_date(data,
      :vvr_uocava_residence_unavailable_since,
      :dob,
      :absentee_until,
      :rights_restored_on)

    Converter.params_to_time(data,
      :ab_time_1, :ab_time_2)

    @registration = Registration.new(data)

    if @registration.save
      RegistrationRepository.store_registration(session, @registration)
      render :show
    else
      flash.now[:error] = 'Please review your request data and try submitting again'
      render :new
    end
  end

  def show
    @registration = current_registration
    @update       = !@registration.previous_data.blank?
    respond_to do |f|
      f.html
      f.pdf do
        doctype = 'VoterRegistrationRequest'

        if @update
          doctype = @registration.requesting_absentee == '1' ? 'AbsenteeRequest+VoterRegistrationUpdateRequest' : 'VoterRegistrationUpdateRequest'
        end

        LogRecord.log(doctype, 'complete', @registration)

        # Doing it in such a weird way because of someone stealing render / render_to_string method from wicked_pdf
        render text: WickedPdf.new.pdf_from_string(
          render_to_string(template: 'registrations/pdf/show', pdf: 'registration.pdf', layout: 'pdf'),
          margin: { top: 5, right: 5, bottom: 5, left: 5 })
      end
      f.xml do
        render 'registrations/xml/show', layout: false
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :root
  end

  def edit
    @registration = current_registration

    LogRecord.log("VoterRegistrationUpdateRequest", "start", @registration)

    # "kind" comes from the review form where we either maintain or
    # change the status.
    @registration.init_update_to(params[:kind].to_s)
  end

  def update
    data = params[:registration]
    Converter.params_to_date(data,
      :vvr_uocava_residence_unavailable_since,
      :dob,
      :absentee_until,
      :rights_restored_on)

    Converter.params_to_time(data,
      :ab_time_1, :ab_time_2)

    @registration = current_registration
    unless @registration.update_attributes(data)
      redirect_to :edit_registration, alert: 'Please review your registration data and try again'
    end
  end

end
