class SupabaseConfig {
  // قم بتغيير هذه القيم بمعلومات مشروع Supabase الخاص بك
  static const String supabaseUrl = 'https://tmluskkfavodevjcmijk.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtbHVza2tmYXZvZGV2amNtaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwMTAzNjgsImV4cCI6MjA2NTU4NjM2OH0.AGnAam_9tD8WJ-qLB8ix5vYLFeb-oXuH2vgla-wE4Ls';
  static const String redirectUrl =
      'io.supabase.monappmealplanning://login-callback/';

  // أسماء المجموعات في Supabase Storage
  static const String recipeImagesStorage = 'recipe_images';
  static const String userAvatarsStorage = 'user_avatars';

  // أسماء الجداول في Supabase
  static const String recipesTable = 'recipes';
  static const String usersTable = 'users';
  static const String weeklyMealPlansTable = 'weekly_meal_plans';
  static const String monthlyMealPlansTable = 'monthly_meal_plans';
  static const String shoppingListsTable = 'shopping_lists';
}
