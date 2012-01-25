package com.chrisumbel.examples;

public class Account {
    private double balance;

    public double getBalance() {
	return this.balance;
    }

    public void credit(double amount) {
	this.balance += amount;
    }

    public void debit(double amount) {
	this.balance -= amount;
    }

    public Account(double balance) {
	this.balance = balance;
    }
}
