# frozen_string_literal: true

module TasksHelper
  def sort_items
    select_hash = []
    select_hash << ['ID(昇順)', 'id asc']
    select_hash << ['ID(降順)', 'id desc']
    select_hash << ['タイトル(昇順)', 'title asc']
    select_hash << ['タイトル(降順)', 'title desc']
    select_hash << ['優先度(昇順)', 'priority asc']
    select_hash << ['優先度(降順)', 'priority desc']
  end
end
