/**
 * This file is part of WormAI: An OpenTTD AI.
 * 
 * @file money.nut Class containing money related functions for WormAI.
 * Requirements: SuperLib.Money.
 *
 * License: GNU GPL - version 2 (see license.txt)
 * Author: Wormnest (Jacob Boerema)
 * Copyright: Jacob Boerema, 2013-2016.
 *
 */ 

/**
 * Define the WormMoney class containing money related functions.
 */
class WormMoney
{
	WM_SILENT = true;
	WM_SHOWINFO = false;

	/** @name Money related functions */
    /// @{
	/**
	 * Check if we have enough money (via loan and on bank).
	 * @param money The amount of money we need.
	 * @return Boolean saying if we do or don't have enough money.
	 */
	static function HasMoney(money);

	/**
	 * Get the amount of money requested, loan if needed.
	 * @param money The amount of money we need.
	 * @param silent (false by default) Whether or not we should show info about failure to get money or getting a loan.
	 * @return Boolean saying if we got the needed money or not.
	 */
	static function GetMoney(money, silent = false);
	
	/**
	 * Compute the amount of money corrected for inflation.
	 * @param money The uncorrected amount of money.
	 * @return The inflation corrected amount of money.
	 * @note Adapted from SuperLib.Money.Inflate: Computes GetInflationRate only once.
	 */
	static function InflationCorrection(money);

	/**
	 * Calculates the minimum amount of cash needed to be at hand. This is used to
	 * avoid going bankrupt because of station maintenance costs.
	 * @note Taken from SimpleAI.
	 * @todo Think of a better computation than stationcount * 50 since I think maintenance costs don't increase linearly.
	 * @return 10000 pounds plus the expected station maintenance costs.
	 */
	function GetMinimumCashNeeded();

	/**
	 * Calculates how much cash will be on hand if the maximum loan is taken.
	 * @return The maximum amount of money.
	 * @note Taken from SimpleAI.
	 */
	function GetMaxBankBalance();
	/// @}

}

function WormMoney::HasMoney(money)
{
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) >= money) return true;
	return false;
}

function WormMoney::GetMoney(money, silent = false)
{
	if (!WormMoney.HasMoney(money)) {
		if (!silent) {
			AILog.Info("We don't have enough money and we also can't loan enough for our needs (" + money + ").");
			AILog.Info("Bank balance: " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + 
				", max loan: " + AICompany.GetMaxLoanAmount() +
				", current loan: " + AICompany.GetLoanAmount());
		}
		return false;
	}
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > money) return true;

	local loan = money - AICompany.GetBankBalance(AICompany.COMPANY_SELF) + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan = loan - loan % AICompany.GetLoanInterval();
	if (!silent)
		AILog.Info("Need a loan to get " + money + ": " + loan);
	return AICompany.SetLoanAmount(loan);
}

function WormMoney::InflationCorrection(money)
{
	/* Using a local variable to compute inflation only once should be faster I think. */
	local inflation = _SuperLib_Money.GetInflationRate();
	return (money / 100) * inflation + (money % 100) * inflation / 100;
}

function WormMoney::GetMinimumCashNeeded()
{
	local stationlist = AIStationList(AIStation.STATION_ANY);
	local maintenance = WormMoney.InflationCorrection(stationlist.Count() * 50);
	/// @todo Maybe also use InflationCorrection on GetLoanInterval or is that already corrected for inflation?
	return maintenance + AICompany.GetLoanInterval();
}

function WormMoney::GetMaxBankBalance()
{
	local balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local maxbalance = balance + AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
	// overflow protection by krinn
	return (maxbalance >= balance) ? maxbalance : balance;
}
