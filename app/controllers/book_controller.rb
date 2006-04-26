require 'time'

# 家計簿機能のコントローラ
class BookController < ApplicationController 
  before_filter :authorize
  attr_accessor :menu_items, :title, :name

  # メニューなどレイアウトに必要な情報を設定する  
  def initialize
    @menu_items = {}
    @menu_items.store("deals", "仕分帳")
    @menu_items.store("display_in_out", "収支表")
    @menu_items.store("account_deals", "口座別出納")
    @title = "家計簿"
    @name = "book"
  end

  def submit_tab
    @date = DateBox.new(params[:date])
    begin
      case params[:tab_action]
        when "save_deal"
          save_deal
        when "save_balance"
          save_balance
        else
          raise Exception("unknown tabaction " + params[:tab_action].to_s)
      end
      @target_month = @date
    rescue => err
      flash[:notice] = "エラーが発生したため記入できませんでした。" + err
      @target_month = session[:target_month]
    end
    prepare_update_deals
    render(:partial => "deals", :layout => false)
  end

  def select_deal_tab
    prepare_select_deal_tab
    render(:partial => "edit_deal", :layout => false)
  end

  # 仕分け帳画面部分だけを更新するためのAjax対応処理
  def update_deals
    @target_month = DateBox.new(params[:target_month])
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
    render(:partial => "deals", :layout => false)
  end

  # 仕分け帳画面を初期表示するための処理
  def deals
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month

    prepare_select_deal_tab
    prepare_update_deals  # 帳簿を更新　成功したら月をセッション格納
  end
  
  
  # 取引内容の変更フォームを表示する
  def edit_deal
    deal = Deal.find(params[:id])
    # todo
    flash[:notice] = "未実装です。"
    redirect_to(:action => 'deals')
  end
  
  # 取引の削除を受け付ける
  def delete_deal
    deal = Deal.find(params[:id])
    deal.destroy_deeply
    flash[:notice] = "取引 #{deal.id} を削除しました。"
    redirect_to(:action => 'deals')
  end
  
  def select_balance_tab
    @accounts_for_balance = Account.find(:all,
     :conditions => ["account_type == 1 and user_id = ?", session[:user].id])
  
    render(:partial => "edit_balance", :layout => false)
  end
  
  # 口座別出納
  def account_deals
    @target_month = session[:target_month]
    @date = @target_month || DateBox.today
    @target_month ||= DateBox.this_month

    # prepare_select_deal_tab
    prepare_update_account_deals  # 帳簿を更新　成功したら月をセッション格納
  end


  private

  # 残高確認記録を登録
  def save_balance
    balance= Balance.new(params[:balance]);
    deal = Deal.create_balance(
      session[:user].id, @date.to_date, nil, balance.account_id_i, balance.amount_i
    )
    flash[:notice] = "記入 #{deal.id} を追加しました。"
  end
  
  # 取引の入力を受け付けて仕分け帳を更新
  def save_deal
    amount = params[:new_amount]
    deal = Deal.create_simple(
      session[:user].id,
      @date.to_date, nil, params[:new_deal_summary],
      params[:new_amount].to_i,
      params[:new_account_minus][:id].to_i,
      params[:new_account_plus][:id].to_i
    )
    flash[:notice] = "記入 #{deal.id} を追加しました。"
  end

  
  def prepare_select_deal_tab
    @accounts_minus = Account.find(:all,
     :conditions => ["account_type != 2 and user_id = ?", session[:user].id])
    @accounts_plus = Account.find(:all,
     :conditions => ["account_type != 3 and user_id = ?", session[:user].id])
  end

  def prepare_update_deals
    begin
      @deals = Deal.get_for_month(session[:user].id, @target_month.year_i, @target_month.month_i)
      session[:target_month] = @target_month
    rescue Exception
      flash[:notice] = "不正な日付です。 " + @target_month.to_s
      @deals = Array.new
    end
  end

  def prepare_update_account_deals
  # todo 
    @account_id = 1
    @accounts = Account.find(:all, :conditions => ["account_type == 1 and user_id = ?", session[:user].id])
    begin
      deals = Deal.get_for_account(session[:user].id, @account_id, @target_month.year_i, @target_month.month_i)
      @account_entries = Array.new();
      @balance_start = AccountEntry.balance_start(session[:user].id, @account_id, @target_month.year_i, @target_month.month_i) # これまでの残高
      balance_estimated = @balance_start
      for deal in deals do
        for account_entry in deal.account_entries do
          if account_entry.account.id != @account_id || account_entry.balance
            if account_entry.balance
              balance_estimated = account_entry.balance
            else
              balance_estimated -= account_entry.amount
              account_entry.balance_estimated = balance_estimated
            end
            @account_entries << account_entry
          end
        end
      end
      @balance_end = @account_entries.last.balance || @account_entries.last.balance_estimated
      session[:target_month] = @target_month
    rescue => err
      flash[:notice] = "不正な日付です。 " + @target_month.to_s + err + err.backtrace.to_s
      @account_entries = Array.new
    end
  end

  
end
