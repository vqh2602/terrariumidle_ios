import Testing
@testable import terrariumidle_ios

struct FormatNumberTests {
    @Test func abbreviatesSmallAndLargeIntegers() {
        #expect(FormatNumber.formatNumber(0) == "0")
        #expect(FormatNumber.formatNumber(999) == "999")
        #expect(FormatNumber.formatNumber(1_000) == "1k")
        #expect(FormatNumber.formatNumber(1_500) == "1.5k")
        #expect(FormatNumber.formatNumber(2_500_000) == "2.5m")
        #expect(FormatNumber.formatNumber(6_585_800_000) == "6.6b")
        #expect(FormatNumber.formatNumber(1_000_000_000_000) == "1t")
        #expect(FormatNumber.formatNumber(3_400_000_000_000_000) == "3.4qa")
        #expect(FormatNumber.formatNumber(9_000_000_000_000_000_000) == "9qi")
    }

    @Test func abbreviatesBeyondIntRangeAndNegatives() {
        #expect(FormatNumber.formatNumber(1.2e21) == "1.2sx")
        #expect(FormatNumber.formatNumber(5e24) == "5sp")
        #expect(FormatNumber.formatNumber(7.5e27) == "7.5oc")
        #expect(FormatNumber.formatNumber(2e30) == "2no")
        #expect(FormatNumber.formatNumber(4.3e33) == "4.3dc")
        #expect(FormatNumber.formatNumber(-1_500_000_000_000) == "-1.5t")
    }
}
