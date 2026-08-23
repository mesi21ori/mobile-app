class S {
  static const appName = 'ሰንበት ትምህርት ቤት';
  static const appSubtitle = 'ንብረትና አልባሳት መቆጣጠሪያ';
  static const login = 'ግባ';
  static const username = 'የተጠቃሚ ስም';
  static const password = 'የይለፍ ቃል';
  static const loginError = 'የተጠቃሚ ስም ወይም የይለፍ ቃል ትክክል አይደለም';
  static const vestments = 'ልብሰ ስብሐት';
  static const inventory = 'ንብረት';
  static const finance = 'ፋይናንስ';
  static const audit = 'ኦዲት';
  static const more = 'ተጨማሪ';
  static const save = 'አስቀምጥ';
  static const cancel = 'ተወው';
  static const add = 'ጨምር';
  static const edit = 'አስተካክል';
  static const search = 'ፈልግ';
  static const success = 'በተሳካ ሁኔታ ተቀምጧል';
  static const error = 'ስህተት ተከስቷል';
  static const superAdmin = 'ዋና አስተዳዳሪ';
  static const admin = 'አስተዳዳሪ';
  static const classLeader = 'መደብ አስተዳዳሪ';
  static const user = 'ተጠቃሚ';
  static const logout = 'ውጣ';
  static const events = 'በዓላት';
  static const groups = 'ምድቦች';
  static const members = 'አባላት';
  static const issue = 'ልብስ አድል';
  static const returnItem = 'ልብስ መልስ';
  static const dirtyList = 'ያልተመለሱ ልብሶች';
  static const returned = 'ተመልሷል';
  static const dirty = 'ቆሽሿል';
  static const washed = 'ታጠበ';
  static const classes = 'ምድቦች';
  static const addClass = 'አዲስ ምድብ';
  static const addStudent = 'ተማሪ ጨምር';
  static const cannotReturnDirty = 'ቆሸሸ ልብስ አይመለስም፤ መጀመሪያ ይታጠብ';
  static const available = 'ያለው';
  static const issued = 'የተወሰደ';
  static const income = 'ገቢ';
  static const expense = 'ወጪ';
  static const net = 'የተጣራ ሂሳብ';
  static const reason = 'ምክንያት';
  static const amount = 'መጠን (ብር)';
  static const checkout = 'ንብረት አውጣ';
  static const checkin = 'ንብረት መልስ';
  static const registerAsset = 'አዲስ ንብረት መዝግብ';
  static const registerIssued = 'ያወጡ ንብረቶች መዝግብ';
  static const issuedItems = 'ያወጡ ንብረቶች';
  static const remove = 'አስወግድ';
  static const intact = 'ደህና ተመልሷል';
  static const damaged = 'የተበላሸ';
  static const lost = 'የጎደለ';
  static const returnable = 'ቋሚ ንብረት';
  static const consumable = 'አላቂ ንብረት';
  static const remainingNow = 'አሁን ያለው';
  static const usedUp = 'የተጠቀመ';
  static const departments = 'ክፍሎች';
  static const users = 'ተጠቃሚዎች';
  static const approve = 'አጽድቅ';
  static const threeMonths = '3 ወር';
  static const sixMonths = '6 ወር';
  static const physical = 'በአካል የተገኘ';
  static const systemQty = 'በሲስተም ያለው';
  static const difference = 'ልዩነት';
  static const penalty = 'ቅጣት';
  static const bulkIssue = 'ለሁሉም አድል';
  static const registerParticipants = 'ተሳታፊዎችን መዝግብ';
  static const eventParticipants = 'የበዓል ተሳታፊዎች';
  static const issueClothes = 'ልብስ አድል';
  static const apiUrl = 'የሰርቨር አድራሻ';
  static const exportDoc = 'ወደ ሰነድ ላክ';

  static String roleLabel(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return superAdmin;
      case 'ADMIN':
        return admin;
      case 'CLASS_LEADER':
        return classLeader;
      default:
        return user;
    }
  }
}
