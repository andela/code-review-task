class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @articles = Article.all.includes(:user)

    if params[:tag].present?
      @articles = @articles.tagged_with(params[:tag])
    elsif params[:author].present?
      @articles = @articles.authored_by(params[:author])
    elsif params[:favorited].present?
      @articles = @articles.favorited_by(params[:favorited])
    end

    @articles_count = @articles.count
    offset = 0
    limit = 20
    if params[:offset]
      offset = params[:offset]
    end
    if params[:limit]
      limit = params[:limit]
    end
    @articles = @articles.order(created_at: :desc).offset(offset).limit(limit)
  end

  def feed
    @articles = Article.includes(:user).where(user: current_user.following_users)

    @articles_count = @articles.count
    if params[:offset]
      offset = params[:offset]
    end
    if params[:limit]
      limit = params[:limit]
    end
    @articles = @articles.order(created_at: :desc).offset(offset).limit(limit)
    render :index
  end

  def create
    @article = Article.new(articleParams)
    @article.user = current_user

    if @article.save
      render :show
    else
      render json: { errors: @article.errors }, status: => 422
    end
  end

  def show
    @article = Article.find_by_slug!(params[:slug])
  end

  def update
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.update_attributes(articleParams)
      render :show
    else
      render json: { errors: { article: ['not owned by user'] } }, status: :forbidden
    end
  end

  def destroy
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.destroy

      render json: {}
    else
      render json: { errors: { article: ['not owned by user'] } }, status: :unprocessable_entity
    end
  end

  def articleParams
    params.require(:article).permit(:title, :body, :description, tag_list: [])
  end
end
