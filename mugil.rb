require 'highline/import'

class Mugil < Thor

  desc "Find IP for autoscaling groups", "mugil get_ip"
  def get_ip
    autoscaling = Aws::AutoScaling::Client.new(region: 'ap-southeast-1')
    groups = autoscaling.describe_auto_scaling_groups.data.auto_scaling_groups
    group_names = autoscaling.describe_auto_scaling_groups.data.auto_scaling_groups.collect(&:auto_scaling_group_name)
    choose do |menu|
      menu.prompt = say(set_color "Choose the auto scaling group", :green, :on_black, :bold)
      groups.each do |asg|
        menu.choice(asg.auto_scaling_group_name){get_instance_ips(asg)}
      end
    end
    nil
  end

  private
  def get_instance_ips(asg)
    say("Fetching IPs for "+set_color(asg.auto_scaling_group_name, :green, :on_black, :bold))
    ec2 = Aws::EC2::Client.new(region: 'ap-southeast-1')
    instance_results = ec2.describe_instances({instance_ids: asg.instances.collect(&:instance_id)})
    ips = instance_results.data.reservations.map{|a| a.instances.map(&:public_ip_address)}.flatten
    say("IPs", :green, :bold)
    ips.each do |ip|
      say(set_color(ip, :green, :bold)+" | ssh -i ~/.ssh/arvindc.pem ec2-user@#{ip}")
    end
  end
end
