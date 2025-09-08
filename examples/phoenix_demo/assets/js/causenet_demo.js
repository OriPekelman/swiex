// CauseNet + Prolog Demo JavaScript
// Separated from HTML template for better organization

// Tab switching functionality
function showTab(tabName) {
  // Hide all tab contents
  document.querySelectorAll('.tab-content').forEach(content => {
    content.classList.add('hidden');
  });
  
  // Remove active class from all tab buttons
  document.querySelectorAll('.tab-button').forEach(button => {
    button.classList.remove('active', 'bg-blue-100', 'text-blue-700');
    button.classList.add('text-gray-600', 'hover:text-gray-900');
  });
  
  // Show selected tab content
  document.getElementById(tabName).classList.remove('hidden');
  
  // Add active class to selected tab button
  const activeButton = document.querySelector(`[data-tab="${tabName}"]`);
  activeButton.classList.add('active', 'bg-blue-100', 'text-blue-700');
  activeButton.classList.remove('text-gray-600', 'hover:text-gray-900');
}

// Causal Reasoning Functions
function loadCausalExample(start, end) {
  document.getElementById('startConcept').value = start;
  document.getElementById('endConcept').value = end;
  findCausalPaths();
}

async function findCausalPaths() {
  const startConcept = document.getElementById('startConcept').value.trim();
  const endConcept = document.getElementById('endConcept').value.trim();
  
  if (!startConcept || !endConcept) {
    alert('Please enter both start and end concepts');
    return;
  }
  
  const resultsDiv = document.getElementById('causalResults');
  resultsDiv.innerHTML = '<div class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div><p class="mt-2">Finding causal paths...</p></div>';
  
  try {
    const response = await fetch('/api/causenet/causal_paths', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        start: startConcept,
        end: endConcept
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      displayCausalResults(data);
    } else {
      displayError(resultsDiv, data.error);
    }
  } catch (error) {
    displayError(resultsDiv, 'Network error: ' + error.message);
  }
}

function displayCausalResults(data) {
  const resultsDiv = document.getElementById('causalResults');
  
  let html = `
    <div class="mb-6">
      <div class="text-lg font-semibold text-gray-900 mb-2">
        Causal Paths from "${data.start_concept}" to "${data.end_concept}"
      </div>
      <div class="text-sm text-gray-600">Found ${data.count} pathway(s)</div>
    </div>
  `;
  
  if (data.paths && data.paths.length > 0) {
    html += '<div class="space-y-4">';
    data.paths.forEach((path, index) => {
      html += `
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="font-medium text-blue-800 mb-2">Pathway ${index + 1}:</div>
          <div class="flex items-center space-x-2 text-sm">
            ${path.map((concept, i) => `
              <span class="bg-white px-3 py-1 rounded-full border border-blue-200">${concept}</span>
              ${i < path.length - 1 ? '<span class="text-blue-400">→</span>' : ''}
            `).join('')}
          </div>
        </div>
      `;
    });
    html += '</div>';
  } else {
    html += `
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div class="text-yellow-800">No causal pathways found between these concepts.</div>
      </div>
    `;
  }
  
  resultsDiv.innerHTML = html;
}

// Medical Diagnosis Functions
function loadSymptomExample(symptoms) {
  // Clear all checkboxes
  document.querySelectorAll('.symptom-checkbox').forEach(checkbox => {
    checkbox.checked = false;
  });
  
  // Check the specified symptoms
  symptoms.forEach(symptom => {
    const checkbox = document.querySelector(`.symptom-checkbox[value="${symptom}"]`);
    if (checkbox) checkbox.checked = true;
  });
  
  performDiagnosis();
}

async function performDiagnosis() {
  const selectedSymptoms = Array.from(document.querySelectorAll('.symptom-checkbox:checked'))
    .map(checkbox => checkbox.value);
  
  if (selectedSymptoms.length === 0) {
    alert('Please select at least one symptom');
    return;
  }
  
  const resultsDiv = document.getElementById('diagnosisResults');
  resultsDiv.innerHTML = '<div class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600 mx-auto"></div><p class="mt-2">Analyzing symptoms...</p></div>';
  
  try {
    const response = await fetch('/api/causenet/medical_diagnosis', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        symptoms: selectedSymptoms
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      displayDiagnosisResults(data);
    } else {
      displayError(resultsDiv, data.error);
    }
  } catch (error) {
    displayError(resultsDiv, 'Network error: ' + error.message);
  }
}

function displayDiagnosisResults(data) {
  const resultsDiv = document.getElementById('diagnosisResults');
  
  let html = `
    <div class="mb-6">
      <div class="text-lg font-semibold text-gray-900 mb-2">
        Analysis for Symptoms: ${data.symptoms.join(', ')}
      </div>
    </div>
  `;
  
  if (data.possible_conditions && data.possible_conditions.length > 0) {
    html += '<div class="space-y-4">';
    data.possible_conditions.forEach((condition, index) => {
      html += `
        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="font-medium text-green-800 mb-2">Possible Condition ${index + 1}:</div>
          <div class="text-sm text-green-700">
            <div class="mb-2"><strong>Disease:</strong> ${condition.disease}</div>
            <div><strong>Progression:</strong> ${condition.progression.join(' → ')}</div>
          </div>
        </div>
      `;
    });
    html += '</div>';
  } else {
    html += `
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div class="text-yellow-800">No specific conditions identified for these symptoms.</div>
      </div>
    `;
  }
  
  resultsDiv.innerHTML = html;
}

// Constraint Solving Functions
function solveNQueens() {
  const n = parseInt(document.getElementById('queensCount').value);
  if (n < 4 || n > 12) {
    alert('Please enter a number between 4 and 12');
    return;
  }
  
  const resultsDiv = document.getElementById('queensResults');
  resultsDiv.innerHTML = '<div class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto"></div><p class="mt-2">Solving N-Queens puzzle...</p></div>';
  
  fetch('/api/causenet/constraint_solver', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({
      puzzle: 'n_queens',
      params: { n: n }
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      displayQueensResults(data);
    } else {
      displayError(resultsDiv, data.error);
    }
  })
  .catch(error => {
    displayError(resultsDiv, 'Network error: ' + error.message);
  });
}

function displayQueensResults(data) {
  const resultsDiv = document.getElementById('queensResults');
  
  let html = `
    <div class="mb-4">
      <div class="text-lg font-semibold text-gray-900 mb-2">
        ${data.n}-Queens Solutions
      </div>
      <div class="text-sm text-gray-600">Found ${data.count} solution(s)</div>
    </div>
  `;
  
  if (data.solutions && data.solutions.length > 0) {
    html += '<div class="space-y-4">';
    data.solutions.slice(0, 3).forEach((solution, index) => {
      html += `
        <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div class="font-medium text-purple-800 mb-2">Solution ${index + 1}:</div>
          <div class="text-sm font-mono">${JSON.stringify(solution)}</div>
        </div>
      `;
    });
    
    if (data.count > 3) {
      html += `
        <div class="text-center text-sm text-gray-600">
          ... and ${data.count - 3} more solutions
        </div>
      `;
    }
    
    html += '</div>';
  }
  
  resultsDiv.innerHTML = html;
}

// Sudoku Functions
function generateSudokuGrid() {
  const grid = document.getElementById('sudokuGrid');
  grid.innerHTML = '';
  
  for (let i = 0; i < 9; i++) {
    for (let j = 0; j < 9; j++) {
      const input = document.createElement('input');
      input.type = 'number';
      input.min = '1';
      input.max = '9';
      input.className = 'w-8 h-8 text-center border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent';
      input.dataset.row = i;
      input.dataset.col = j;
      grid.appendChild(input);
    }
  }
}

function clearSudokuGrid() {
  const inputs = document.querySelectorAll('#sudokuGrid input');
  inputs.forEach(input => input.value = '');
}

function solveSudoku() {
  const inputs = document.querySelectorAll('#sudokuGrid input');
  const grid = [];
  
  for (let i = 0; i < 9; i++) {
    grid[i] = [];
    for (let j = 0; j < 9; j++) {
      const input = document.querySelector(`#sudokuGrid input[data-row="${i}"][data-col="${j}"]`);
      grid[i][j] = input.value ? parseInt(input.value) : 0;
    }
  }
  
  const resultsDiv = document.getElementById('sudokuResults');
  resultsDiv.innerHTML = '<div class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600 mx-auto"></div><p class="mt-2">Solving Sudoku...</p></div>';
  
  fetch('/api/causenet/constraint_solver', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({
      puzzle: 'sudoku',
      params: { grid: grid }
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      displaySudokuResults(data);
    } else {
      displayError(resultsDiv, data.error);
    }
  })
  .catch(error => {
    displayError(resultsDiv, 'Network error: ' + error.message);
  });
}

function displaySudokuResults(data) {
  const resultsDiv = document.getElementById('sudokuResults');
  
  let html = `
    <div class="mb-4">
      <div class="text-lg font-semibold text-gray-900 mb-2">
        Sudoku Solutions
      </div>
      <div class="text-sm text-gray-600">Found ${data.count} solution(s)</div>
    </div>
  `;
  
  if (data.solutions && data.solutions.length > 0) {
    html += '<div class="space-y-4">';
    data.solutions.slice(0, 2).forEach((solution, index) => {
      html += `
        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="font-medium text-green-800 mb-2">Solution ${index + 1}:</div>
          <div class="text-xs font-mono">${JSON.stringify(solution)}</div>
        </div>
      `;
    });
    
    if (data.count > 2) {
      html += `
        <div class="text-center text-sm text-gray-600">
          ... and ${data.count - 2} more solutions
        </div>
      `;
    }
    
    html += '</div>';
  }
  
  resultsDiv.innerHTML = html;
}

// Prolog Playground Functions
function loadPlaygroundExample(query, setup) {
  document.getElementById('playgroundQuery').value = query;
  document.getElementById('playgroundSetup').value = setup;
}

async function executePrologQuery() {
  const query = document.getElementById('playgroundQuery').value.trim();
  const setup = document.getElementById('playgroundSetup').value.trim();
  
  if (!query) {
    alert('Please enter a Prolog query');
    return;
  }
  
  const resultsDiv = document.getElementById('playgroundResults');
  resultsDiv.innerHTML = '<div class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div><p class="mt-2">Executing Prolog query...</p></div>';
  
  try {
    const response = await fetch('/prolog/query', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        query: query,
        setupCode: setup
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      displayPlaygroundResults(data);
    } else {
      displayError(resultsDiv, data.error);
    }
  } catch (error) {
    displayError(resultsDiv, 'Network error: ' + error.message);
  }
}

function displayPlaygroundResults(data) {
  const resultsDiv = document.getElementById('playgroundResults');
  
  let html = `
    <div class="mb-4">
      <div class="text-sm text-gray-600 mb-2">Query:</div>
      <div class="font-mono bg-gray-100 p-2 rounded text-sm">${data.query}</div>
    </div>
  `;
  
  if (data.results && data.results.length > 0) {
    html += `
      <div class="mb-4">
        <div class="text-sm text-gray-600 mb-2">Results (${data.results.length} solution${data.results.length > 1 ? 's' : ''}):</div>
        <div class="space-y-2">
    `;
    data.results.forEach((result, index) => {
      html += `
        <div class="bg-indigo-50 border border-indigo-200 rounded p-3">
          <div class="text-sm font-medium text-indigo-800 mb-1">Solution ${index + 1}:</div>
          <div class="font-mono text-sm">
      `;
      Object.entries(result).forEach(([variable, value]) => {
        html += `<div>${variable} = ${JSON.stringify(value)}</div>`;
      });
      html += `
          </div>
        </div>
      `;
    });
    html += `
        </div>
      </div>
    `;
  } else {
    html += `
      <div class="bg-yellow-50 border border-yellow-200 rounded p-3">
        <div class="text-sm text-yellow-800">No solutions found</div>
      </div>
    `;
  }
  
  resultsDiv.innerHTML = html;
}

// Utility Functions
function displayError(container, message) {
  container.innerHTML = `
    <div class="bg-red-50 border border-red-200 rounded-lg p-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Error</h3>
          <div class="mt-2 text-sm text-red-700">${message}</div>
        </div>
      </div>
    </div>
  `;
}

// Initialize the page
document.addEventListener('DOMContentLoaded', function() {
  // Generate initial Sudoku grid
  generateSudokuGrid();
  
  // Set first tab as active
  showTab('causal-reasoning');
});
