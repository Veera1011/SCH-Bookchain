import 'package:supabase/supabase.dart';

void main() async {
  // Replace these with actual values from the project
  final supabaseUrl = ''; 
  final supabaseKey = ''; 

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('Please provide your Supabase URL and Service Role Key.');
    print('You can find them in the Supabase Dashboard -> Settings -> API.');
    return;
  }

  // NOTE: Use the service role key to bypass RLS policies for bulk insert
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  print('Starting to generate mock data...');

  // 1. Create a dummy location (Branch/Office)
  final locationData = {
    'name': 'Main NY Office',
    'address': '123 Tech Avenue, New York',
    'is_active': true,
  };

  try {
    print('Inserting Location...');
    // We expect the locations table to have an auto-generated UUID or serial id
    final locationResponse = await supabase
        .from('locations')
        .insert(locationData)
        .select()
        .single();
    
    final locationId = locationResponse['id'];
    print('✅ Location inserted: $locationId');

    // 2. Generate multiple mock users
    List<Map<String, dynamic>> usersToInsert = [];
    
    final names = ['Alice Smith', 'Bob Jones', 'Charlie Brown', 'Diana Prince', 'Eve Adams'];
    final departments = ['Engineering', 'Marketing', 'Sales', 'HR', 'Finance'];

    for (int i = 0; i < names.length; i++) {
      // NOTE: For full Auth integration, users must be created via Supabase Auth first, 
      // but for testing purposes and if we only care about the 'profiles' table showing up in lists:
      usersToInsert.add({
        // If 'id' is linked to auth.users, this might fail unless we insert into auth.users first,
        // or we use a separate testing method. 
        // We will generate random UUIDs for profiles, assuming RLS allows it with Service Role Key.
        // It's recommended to create real users via the app UI for testing Auth.
        'id': '00000000-0000-0000-0000-00000000000${i.toString()}', // Dummy UUIDs for profiles
        'name': names[i],
        'email': '${names[i].split(' ')[0].toLowerCase()}@example.com',
        'role': i == 0 ? 'super_admin' : 'employee', // Alice is admin
        'status': i == 4 ? 'pending' : 'active',     // Eve is pending approval
        'location_id': locationId,
        'department': departments[i],
        'points': i * 15,
        'reading_goal': 12,
        'is_active': true,
      });
    }

    print('Inserting Profiles...');
    await supabase.from('profiles').insert(usersToInsert);
    print('✅ 5 Profiles inserted.');

    // 3. Insert Books
    List<Map<String, dynamic>> booksToInsert = [];
    final bookTitles = ['Clean Code', 'The Pragmatic Programmer', 'Design Patterns', 'Refactoring', 'Domain-Driven Design'];
    final authors = ['Robert C. Martin', 'Andy Hunt', 'Erich Gamma', 'Martin Fowler', 'Eric Evans'];

    for (int i = 0; i < bookTitles.length; i++) {
      booksToInsert.add({
        'title': bookTitles[i],
        'author': authors[i],
        'location_id': locationId,
        'genre': ['Technology', 'Programming'],
        'total_copies': 3,
        'available_copies': 3,
        'is_active': true,
        // 'qr_code': might be required depending on your DB schema setup
      });
    }

    print('Inserting Books...');
    await supabase.from('books').insert(booksToInsert);
    print('✅ 5 Books inserted.');

    print('🎉 Data generation complete!');

  } catch (error) {
    print('❌ Error occurred: $error');
    print('Make sure your tables (locations, profiles, books) exist and match the expected schema.');
  }
}
