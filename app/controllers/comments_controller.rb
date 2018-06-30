# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_task, only: %i[new create edit update destroy]
  before_action :set_comment, only: %i[edit update destroy]

  def new
    @comment = @task.comments.new
  end

  def create
    @comment = @task.comments.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.html { redirect_to tasks_path, notice: t('views.notice.success.register', model: Comment.model_name.human) }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { render :new }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to tasks_path, notice: t('views.notice.success.update', model: Comment.model_name.human) }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to tasks_url, notice: t('views.notice.success.destroy', model: Comment.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

def comment_params
    params.require(:comment).permit(:contents)
  end
end
