# frozen_string_literal: true

class BooksController < ApplicationController
  before_action :find_books, only: [:index]
  before_action :response_headers, only: [:index]
  before_action :find_book, only: [:show]
  before_action :check_range
  before_action :check_pagination

  def_param_group :book do
    param :name, String, desc: 'book_name_loc', required: true
    param :original_name, String, desc: 'book_original_name_loc', required: true
    param :catalog_id, :number, desc: 'book_catalog_id_loc', required: true
    param :author_id, :number, desc: 'author_id_loc', required: true
    param :group_id, :number, desc: 'group_id_loc'
  end

  api :GET, '/books/'
  param_group :errors, ApplicationController
  def index
    render json: @find_books
  end

  api :GET, '/books/:id/'
  param :id, :number, desc: 'book_id_loc', required: true
  param_group :errors, ApplicationController
  def show
    if find_book
      render json: find_book
    else
      bad_request!(message: 'Book not found')
    end
  end

  api :POST, '/books/'
  param_group :book
  param :user_id, :number, desc: 'user_id_loc', required: true
  param_group :errors, ApplicationController
  def create
    if create_book.save
      render json: create_book
    else
      bad_request!(create_book.errors.full_messages)
    end
  end

  api :PATCH, '/books/'
  param_group :book
  param_group :errors, ApplicationController
  def update
    if update_book
      render json: find_book.reload!
    else
      bad_request! find_book: find_book.errors
    end
  end

  private

  def book_update_params
    params.require(:book).permit(
      :name,
      :original_name,
      :catalog_id,
      :author_id,
      :group_id
    )
  end

  def attrs
    {
      name: params[:name],
      range: params[:range],
      author_id: params[:author_id],
      user_id: params[:user_id],
      catalog_id: params[:catalog_id],
      group_id: params[:group_id],
      original_name: params[:original_name]
    }
  end

  def update_book
    bad_request!(book: 'Book not found') unless find_book

    find_book.update(book_update_params)
  end

  def find_book
    @find_book ||= Book.where(id: params[:id])&.first
  end

  def create_book
    @create_book ||= Book.new(attrs.except(:range))
  end

  def range
    @range ||= Ranges.new(range_attrs: attrs[:range])
  end

  def pagination
    @pagination ||= Pagination.new(
      current_page: params.fetch(:page, 1),
      current_page_size: params.fetch(:page_size, 15)
    )
  end

  def check_range
    bad_request!(range.errors.full_messages) if range.invalid?
  end

  def check_pagination
    bad_request!(pagination.errors.full_messages) if pagination.invalid?
  end

  def find_books
    @find_books = Book
    @find_books = @find_books.where(user_id: attrs[:user_id]) if attrs[:user_id].present?
    @find_books = @find_books.where(created_at: range.range) if attrs[:range].present?
    @find_books = @find_books.where(author_id: attrs[:author_id]) if attrs[:author_id].present?
    @find_books = @find_books.where(group_id: attrs[:group_id]) if attrs[:group_id].present?
    @find_books = @find_books.where(catalog_id: attrs[:catalog_id]) if attrs[:catalog_id].present?
    @find_books = @find_books.where(original_name: attrs[:original_name]) if attrs[:original_name].present?
    @find_books = @find_books.where(name: attrs[:name]) if attrs[:name].present?
    @find_books = @find_books.paginate(page: pagination.page, per_page: pagination.page_size)
  end

  def books_count
    @find_books.count
  end

  def total_page_count
    books_count / pagination.page_size
  end

  def response_headers
    response.headers['X-Total-Pages-Count'] = total_page_count.to_s
    response.headers['X-Page-Index'] = pagination.page.to_s
    response.headers['X-Per-Page'] = pagination.page_size.to_s
    response.headers['X-Total-Count'] = books_count.to_s
  end
end
