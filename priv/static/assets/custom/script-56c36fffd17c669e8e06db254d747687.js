document.getElementById('avatar-btn').addEventListener('click', function() {
    document.getElementById('dropdown').classList.toggle('hidden');
  })

    document.getElementById('menu-btn').addEventListener('click', () => {
      const sidebar = document.getElementById('sidebar');
      sidebar.classList.toggle('hidden');
    });

    document.getElementById('hidebar').addEventListener('click', () => {
      const sidebar = document.getElementById('sidebar');
      sidebar.classList.toggle('hidden');
    });

    document.getElementById('toggle-collapse').addEventListener('click', () => {
      const sidebar = document.getElementById('sidebar');
      const mainContent = document.querySelector('.main-content');
      sidebar.classList.toggle('sidebar-expanded');
      if (sidebar.classList.contains('sidebar-expanded')) {
        sidebar.classList.remove('w-48');
        sidebar.classList.add('w-64');
        document.querySelectorAll('.sidebar-link-text').forEach(element => element.classList.remove('hidden'));
        mainContent.classList.add('main-content-expanded');
      } else {
        sidebar.classList.remove('w-64');
        sidebar.classList.add('w-48');
        document.querySelectorAll('.sidebar-link-text').forEach(element => element.classList.add('hidden'));
        mainContent.classList.remove('main-content-expanded');
      }
    });