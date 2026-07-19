#
# Public: methods for getting stats about users on a per domain basis

class UserStats
  # Returns a list of email domains people have used to sign up with and the
  # number of signups for each, ordered by popularity (most popular first)
  def self.list_user_domains(start_date: nil, limit: nil)
    users = User.
      select("lower(substring(email, position('@' in email)+1)) AS domain, " \
             "COUNT(id) AS count").
      group('domain').
      order(Arel.sql('count DESC'))
    users = users.where('created_at >= ?', start_date) if start_date
    users = users.limit(Integer(limit)) if limit

    User.connection.select_all(users.to_sql).to_a
  end

  # Returns the number of domant users for the given domain
  # (A dormant user is one with no requests, tracks or comments)
  def self.count_dormant_users(domain, start_date=nil)
    users = User.
      where.not(id: InfoRequest.where.not(user_id: nil).select(:user_id)).
      where.not(id: TrackThing.where.not(tracking_user_id: nil).select(:tracking_user_id)).
      where.not(id: Comment.where.not(user_id: nil).select(:user_id)).
      where('email LIKE ?', "%@#{User.sanitize_sql_like(domain)}")
    users = users.where('created_at >= ?', start_date) if start_date
    users.count
  end

  # Returns all the Users of a given domain who have not yet been banned
  # and do not have admin privileges
  def self.unbanned_by_domain(domain, start_date=nil)
    eligible = User.
                 where("email LIKE ?", "%@#{domain}").
                   not_banned.
                     where.not(id: User.with_role(:admin).pluck('users.id'))

    if start_date
      eligible.where("created_at >= ?", start_date)
    else
      eligible
    end
  end
end
