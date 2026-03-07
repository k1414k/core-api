class Admin::V1::DashboardController < Admin::V1::BaseController
  def index
    stats = {
      totalUsers: User.count,
      totalItems: Item.count,
      totalOrders: Order.count,
      totalRevenue: Order.joins(:item).sum("items.price"),
      growthRate: {
        users: 0.0,
        items: 0.0,
        orders: 0.0,
        revenue: 0.0
      }
    }

    recent_orders = Order.includes(:item).order(created_at: :desc).limit(10).map do |order|
      {
        id: order.id,
        itemTitle: order.item.title,
        price: order.item.price,
        status: order.status,
        createdAt: order.created_at
      }
    end

    render json: {
      stats: stats,
      recent_orders: recent_orders
    }, status: :ok
  end
end

