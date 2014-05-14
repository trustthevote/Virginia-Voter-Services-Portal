require 'spec_helper'

describe RegistrationsController do

  let(:af) { double }
  let(:current_registration) { FactoryGirl.build(:registration) }
  before { controller.stub(:current_registration).and_return(current_registration) }

  describe 'new' do
    before  { expect(controller).to receive(:no_forms?).and_return(false) }
    before  { expect(RegistrationRepository).to receive(:pop_search_query).and_return({ first_name: 'Tester' }) }
    before  { expect(ActiveForm).to receive(:mark!) }
    before  { get :new }
    specify { assigns(:registration).first_name.should == 'Tester' }
  end

  describe 'new when no forms is set' do
    before  { expect(controller).to receive(:no_forms?).and_return(true) }
    before  { get :new }
    it      { should redirect_to :about_registration_page }
  end

  describe 'create' do
    it 'should not let users finish registration when form expired' do
      expect(ActiveForm).to receive(:find_for_session!).and_raise(ActiveForm::Expired)
      post :create, registration: {}
      should render_template :expired
    end

    context 'with valid form session' do
      before do
        expect(ActiveForm).to receive(:find_for_session!).and_return(af)
        af.stub(unmark!: true)
        session[:slr_id] = 'slr_id'
      end

      context 'eligible record' do
        before { expect_any_instance_of(Registration).to receive(:eligible?).and_return(true) }

        it 'should save and submit successfully' do
          expect(SubmitEml310).to receive(:submit_new).with(kind_of(Registration)).and_return(true)
          expect(af).to receive(:unmark!)
          expect(LogRecord).to receive(:complete_new).with(kind_of(Registration), 'slr_id')

          post :create, registration: {}
          should render_template :create
          session[:registration_id].should == assigns(:registration).id
          assigns(:registration).reload.submission_failed.should_not be_true
          assigns(:paperless_submission).should be_false
        end

        it 'should mark the record as failed submission' do
          expect(SubmitEml310).to receive(:submit_new).and_raise(SubmitEml310::SubmissionError)
          post :create, registration: {}
          assigns(:registration).reload.submission_failed.should be_true
        end

        it 'should log the submission of a record with DMV ID' do
          SubmitEml310.stub(submit_new: true)
          expect(LogRecord).to receive(:submit_new).with(kind_of(Registration), 'slr_id')
          post :create, registration: { dmv_id: '123123123' }
          assigns(:paperless_submission).should be_true
          should render_template :create
        end
      end

      context 'ineligible record' do
        before { expect_any_instance_of(Registration).to receive(:eligible?).and_return(false) }
        it 'should mark the record as failed submission' do
          expect(SubmitEml310).to_not receive(:submit_new)
          post :create, registration: {}
        end
      end

      it 'should return to the form on failure' do
        expect(SubmitEml310).to_not receive(:submit_new)

        expect(af).to_not receive(:unmark!)
        expect(af).to receive(:touch)
        req = double(save: false)
        Registration.stub(:new).and_return(req)
        post :create, registration: {}
        should render_template :new
        flash[:error].should =~ /review/
      end
    end
  end

  describe 'show' do
    it 'should render template with saved registration' do
      expect(controller).to receive(:current_registration).and_return(current_registration)
      get :show, format: 'pdf'
      assigns(:pdf).should be
    end

    it 'should redirect to new registration page if there is no registration' do
      expect(controller).to receive(:current_registration).and_return(nil)
      get :show
      should redirect_to :root
    end
  end

  describe 'show' do
    before  { get :show }
    specify { assigns(:registration).should == current_registration }
    it      { should render_template :show }
  end

  describe 'edit' do
    before  { expect(ActiveForm).to receive(:mark!) }
    before  { get :edit }
    specify { assigns(:registration).should == current_registration }
    it      { should render_template :edit }
  end

  describe 'update' do
    it 'should not let users finish update when form expired' do
      expect(ActiveForm).to receive(:find_for_session!).and_raise(ActiveForm::Expired)
      put :update, registration: {}
      should render_template :expired
    end

    context 'with valid form session' do
      before do
        expect(ActiveForm).to receive(:find_for_session!).and_return(af)
        SubmitEml310.stub(:submit_update)
      end

      it 'should set saved lookup DOB' do
        dob = 40.years.ago
        expect(controller).to receive(:finalize_update)
        expect(RegistrationRepository).to receive(:pop_lookup_data).and_return({ dob: dob })
        put :update, registration: {}
        assigns(:registration).dob.should == dob
      end

      it 'should save valid data' do
        expect(af).to receive(:unmark!)
        expect(current_registration).to receive(:update_attributes).and_return(true)
        put :update, registration: {}
        assigns(:registration).should == current_registration
        should render_template :update
      end

      it 'should redirect to the form on invalid data' do
        expect(af).to receive(:touch)
        expect(controller).to_not receive(:finalize_update)
        expect(current_registration).to receive(:update_attributes).and_return(false)
        put :update, registration: {}
        should redirect_to :edit_registration
      end
    end
  end

  describe 'submitting update EML310' do
    let(:ses) { {} }
    let(:reg) { Registration.new }

    before do
      af.stub(:unmark!)
    end

    it 'should not submit if SSN is missing' do
      AppConfig['ssn_required'] = true
      expect(SubmitEml310).to_not receive(:submit_update)
      controller.send(:finalize_update, af, reg, ses)
    end

    it 'should submit if SSN is missing' do
      AppConfig['ssn_required'] = false
      expect(SubmitEml310).to receive(:submit_update).and_return(true)
      controller.send(:finalize_update, af, reg, ses)
    end

    it 'should submit if SSN is present' do
      reg.ssn = "123456789"
      expect(SubmitEml310).to receive(:submit_update).with(reg).and_return(true)
      controller.send(:finalize_update, af, reg, ses)
    end

    # Internal error log should contain the error code from the API, and the voter ID, but no other information about the voter.
    it 'should log error if submission failed' do
      reg.ssn = "123456789"
      reg.voter_id = 123
      expect(SubmitEml310).to receive(:submit_update).and_raise(SubmitEml310::SubmissionError.new('code', 'msg'))
      expect(ErrorLogRecord).to receive(:log).with("Failed to submit update EML310", { code: 'code', message: 'msg', voter_id: 123 })
      controller.send(:finalize_update, af, reg, ses)

      reg.reload.submission_failed.should be_true
    end
  end
end
