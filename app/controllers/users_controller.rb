# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :find_users, only: [:index]
  before_action :response_headers, only: [:index]
  before_action :find_user, only: [:show]

  def index
    render json: @users
  end

  def show
    if find_user
      render json: find_user
    else
      render json: {message: 'User not found'}, status: 404
    end
  end

  def create
    if create_user.save
      render json: create_user
    else
      bad_request!(create_user.errors.full_messages)
    end
  end

  def attrs
    {
      name: params[:name]
    }
  end

  def find_user
    @find_user ||= User.where(id: params[:id]).first
  end

  def create_user
    @create_user ||= User.new(attrs)
  end

  def page
    params.fetch(:page, 1).to_i
  end

  def per_page
    params.fetch(:page_size, 12).to_i
  end

  def find_users
    @users ||= User.paginate(page: page, per_page: per_page)
  end

  def users_count
    @users.count
  end

  def total_page_count
    users_count / per_page
  end

  def response_headers
    response.headers['X-Total-Pages-Count'] = total_page_count.to_s
    response.headers['X-Page-Index'] = page.to_s
    response.headers['X-Per-Page'] = per_page.to_s
    response.headers['X-Total-Count'] = users_count.to_s
  end
end
