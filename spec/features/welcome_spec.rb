# -*- encoding : utf-8 -*-
require 'spec_helper'

describe WelcomeController do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  shared_examples "index for pc" do
    it {page.should have_content('Web家計簿 小槌')}
    it {page.should_not have_css("h1.mobile_title")}
  end

  shared_examples "index for mobile" do
    it {page.should have_content('Web家計簿 小槌')}
    it {page.should have_css("h1.mobile_title")}
  end

  shared_examples "having login form" do
    it {page.should have_css("div#login_form")}
  end
  
  shared_examples "not having login form" do
    it {page.should_not have_css("div#login_form")}
  end

  shared_examples "having 簡単ログイン button" do
    it {page.should have_css("input#passportButton")}
  end

  shared_examples "not having 簡単ログイン button" do
    it {page.should_not have_css("input#passportButton")}
  end

  shared_examples "having welcome message" do
    it {page.should have_content('ようこそ')}
  end

  shared_examples "not having welcome message" do
    it {page.should_not have_content('ようこそ')}
  end

  shared_examples "having news contents" do
    it {page.should have_css("div#newsContents")}
  end

  shared_examples "not having news contents" do
    it {page.should_not have_css("div#newsContents")}
  end

  shared_examples "having news errors" do
    it {page.should_not have_css("div#newsContents")}
    it {page.should have_content("現在、ニュースを表示できません。")}
  end

  describe "GET /" do
    context "requested from pc" do
      context "when not logged in" do

        context "when News works fine" do
          before do
            News.stub!(:get).and_return("ニュースです") # for speed up
            visit "/"
          end
          it_behaves_like "index for pc"
          it_behaves_like "having login form"
          it_behaves_like "having news contents"
        end

        context "when News occurs errors" do
          before do
            News.stub!(:get).and_return(nil)
            visit "/"
          end
          it_behaves_like "index for pc"
          it_behaves_like "having login form"
          it_behaves_like "having news errors"
        end
      end

      context "when logged in" do
        include_context "太郎 logged in"

        before do
          visit "/"
        end
        it_behaves_like "index for pc"
        it_behaves_like "not having login form"
        it_behaves_like "having news contents"
      end
    end

    context "requested from AU" do
      include_context "requested from AU"
      context "without a passport" do
        context "when not logged in" do
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "having login form"
          it_behaves_like "not having welcome message"
          it_behaves_like "not having news contents"
          it_behaves_like "not having 簡単ログイン button"
        end

        context "when logged in" do
          include_context "no_mobile_ident_user logged in"
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "not having login form"
          it_behaves_like "having welcome message"
          it_behaves_like "not having news contents"
        end
      end

      context "with the passport" do
        include_context "with the passport for AU"
        before do
          visit "/"
        end
        it_behaves_like "index for mobile"
        it_behaves_like "not having login form"
        it_behaves_like "having welcome message"
        it_behaves_like "not having news contents"
      end
    end

    context "requested from DoCoMo" do
      include_context "requested from DoCoMo"
      context "without a passport" do
        context "when not logged in" do
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "having login form"
          it_behaves_like "not having welcome message"
          it_behaves_like "not having news contents"
          it_behaves_like "having 簡単ログイン button"
       end

        context "when logged in" do
          include_context "no_mobile_ident_user logged in"
          before do
            visit "/"
          end
          it_behaves_like "index for mobile"
          it_behaves_like "not having login form"
          it_behaves_like "having welcome message"
          it_behaves_like "not having news contents"
          it_behaves_like "not having 簡単ログイン button"
       end
      end

      context "with the passport" do
        include_context "with the passport for DoCoMo"
        before do
          visit "/"
        end
        it_behaves_like "index for mobile"
        it_behaves_like "not having login form"
        it_behaves_like "having welcome message"
        it_behaves_like "not having news contents"
      end
    end

    describe "link ユーザー登録 (requested from pc, when not logged in)" do
      before do
        visit "/"
        click_link("ユーザー登録")
      end
      it_behaves_like "users/new"
    end

    describe "link パスワードを忘れたとき (requested from pc, when not logged in)" do
      before do
        visit "/"
        click_link("パスワードを忘れたとき")
      end
      it_behaves_like "users/forgot_password"
    end

    describe "button 簡単ログイン (requested from DoCoMo device, when not logged in)" do
      include_context "requested from DoCoMo without X_DCMGUID"
      context "with the passport" do
        include_context "with the passport for DoCoMo via utn"
        before do
          visit "/"
        end
        include_context "requested from DoCoMo without X_DCMGUID for utn form"
        before do
          click_button "passportButton"
        end
        it_behaves_like "home/index_mobile"
      end
      context "without a passport" do
        before do
          visit "/"
        end
        include_context "requested from DoCoMo without X_DCMGUID for utn form"
        before do
          click_button "passportButton"
        end
        it {page.should have_content("に失敗しました")}
      end
    end

  end

end
