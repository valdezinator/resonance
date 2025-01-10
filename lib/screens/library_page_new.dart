// import 'package:flutter/material.dart';

// class LibraryPage extends StatefulWidget {
//   final void Function(int) onNavigate;
  
//   const LibraryPage({Key? key, required this.onNavigate}) : super(key: key);

//   @override
//   State<LibraryPage> createState() => _LibraryPageState();
// }

// class _LibraryPageState extends State<LibraryPage> {
//   bool _isGridView = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0C0F14),
//         title: Text(
//           'Library',
//           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
//             onPressed: () {
//               setState(() {
//                 _isGridView = !_isGridView;
//               });
//             },
//           ),
//         ],
//       ),
//       body: _isGridView ? _buildGridView() : _buildListView(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // TODO: Implement playlist creation
//           showCreatePlaylistDialog();
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildGridView() {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1,
//       ),
//       itemCount: 0, // TODO: Replace with actual playlist count
//       itemBuilder: (context, index) {
//         return const Card(
//           child: Center(
//             child: Text('Playlist placeholder'),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildListView() {
//     return ListView.builder(
//       itemCount: 0, // TODO: Replace with actual playlist count
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: const Icon(Icons.playlist_play),
//           title: Text('Playlist ${index + 1}'),
//           subtitle: const Text('0 songs'),
//           onTap: () {
//             // TODO: Implement playlist opening
//           },
//         );
//       },
//     );
//   }

//   void showCreatePlaylistDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         final textController = TextEditingController();
//         return AlertDialog(
//           title: const Text('Create New Playlist'),
//           content: TextField(
//             controller: textController,
//             decoration: const InputDecoration(
//               hintText: 'Playlist name',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 // TODO: Implement playlist creation logic
//                 Navigator.pop(context);
//               },
//               child: const Text('Create'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
