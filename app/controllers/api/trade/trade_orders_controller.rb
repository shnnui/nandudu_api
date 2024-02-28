class Api::Trade::TradeOrdersController < ActionController::Base
  def get_providerable_ids
    if params[:providerable_type] == 'Company'
      # 供应商
      data = {
        list: Company.all.map{|company| {id: company.id, name: company.name}}
      }
    else
      # 平台管理用户
      data = {
        list: Organization.using_organizations.map{|organization| {id: organization.id, name: organization.name}}
      }
    end
    render json: {
      code: 0,
      data: data
    }
  end
end