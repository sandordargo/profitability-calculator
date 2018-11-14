class PropertyData {
  final int simplePrice;
  final int simpleMonthlyRent;
  final int simpleMonthlyCharges;
  final int detailedPrice;
  final int detailsNotaryFee;
  final int detailedCommission;
  final int detailedMonthlyRent;
  final int detailedMonthlyCharges;
  final int detailedYearlyPropertyTax;
  final String URL;
  final String remark;
  int id;

  PropertyData(this.simplePrice, this.simpleMonthlyRent,
      this.simpleMonthlyCharges, this.detailedPrice,
      this.detailsNotaryFee, this.detailedCommission,
      this.detailedMonthlyRent, this.detailedMonthlyCharges,
      this.detailedYearlyPropertyTax, [this.URL = "", this.remark = "", this.id]);

  double calculateRentability() {
    if (simplePrice > 0) {
      var yearlyRent = simpleMonthlyRent * 12;
      var yearlyCosts = simpleMonthlyRent + simpleMonthlyCharges * 12;
      var oneTimeCosts = simplePrice * 1.07;
      return (yearlyRent - yearlyCosts) / oneTimeCosts * 100;
    }
    if (detailedPrice > 0) {
      var yearlyRent = detailedMonthlyRent * 12;
      var yearlyCosts = detailedMonthlyCharges * 12 +
          detailedYearlyPropertyTax;
      var oneTimeCosts = detailedPrice +
          detailsNotaryFee +
          detailedCommission;
      return (yearlyRent - yearlyCosts) / oneTimeCosts * 100;
    }
    return 0.0;
  }
}