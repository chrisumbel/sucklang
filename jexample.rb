include Java

puts 1.0.to_java.class
puts "hello, word!".to_java.class

require 'examples.jar'
java_import com.chrisumbel.examples.Account

account = Account.new(10.00)
account.credit(0.5)
account.debit(0.25)

puts account.getBalance
puts account.get_balance
puts account.balance

