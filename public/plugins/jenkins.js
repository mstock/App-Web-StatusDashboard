(function () {
	'use strict';

	angular.module('StatusDashboard').directive('jenkins', [
		'statusService',
		function (statusService) {
			var jobStates = [
				{ label: 'Successful',           color: 'blue',         renderColor: '#5CB85C' },
				{ label: 'Successful, building', color: 'blue_anime',   renderColor: '#3CA83C' },
				{ label: 'Unstable',             color: 'yellow',       renderColor: '#F0AD4E' },
				{ label: 'Unstable, building',   color: 'yellow_anime', renderColor: '#D08D2E' },
				{ label: 'Failed',               color: 'red',          renderColor: '#D9534F' },
				{ label: 'Failed, building',     color: 'red_anime',    renderColor: '#A9332F' },
				{ label: 'Disabled',             color: 'disabled',     renderColor: '#5BC0DE' }
			];
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.jobStats = {};
					scope.chartLabels = jobStates.map(function (state) {
						return state.label;
					});
					scope.chartColors = jobStates.map(function (state) {
						return state.renderColor;
					});
					scope.chartOptions = {};

					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}

						var executors = newValue.executors;
						scope.totalExecutors = executors.totalExecutors;
						scope.busyExecutors  = executors.busyExecutors;
						scope.idleExecutors  = executors.totalExecutors - executors.busyExecutors;
						scope.busyPercent    = 100 * executors.busyExecutors / executors.totalExecutors;
						scope.idlePercent    = 100 - scope.busyPercent;

						jobStates.forEach(function (state) {
							scope.jobStats[state.color] = {
								count: 0
							};
						});
						newValue.jobs.forEach(function (job) {
							scope.jobStats[job.color].count++;
						});
						scope.chartData = jobStates.map(function (state) {
							return scope.jobStats[state.color].count;
						});
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/jenkins.html',
				scope:       {
					statusId:    '@statusId',
					titleSuffix: '@titleSuffix'
				}
			}
		}
	]);
}());
