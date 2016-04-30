(function () {
	'use strict';

	angular.module('StatusDashboard').directive('jiraIssues', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.chartLabels = []
					scope.chartData = [[]];

					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						var statusStats = {};
						newValue.forEach(function (issue) {
							var status = issue.fields.status;
							if (!statusStats[status.id]) {
								statusStats[status.id] = {
									name:  status.name,
									count: 0
								};
							}
							statusStats[status.id].count++;
						});
						scope.chartLabels.length = 0;
						scope.chartData[0].length = 0;
						Object.keys(statusStats).sort().forEach(function (id) {
							scope.chartLabels.push(statusStats[id].name);
							scope.chartData[0].push(statusStats[id].count);
						});
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/jira-issues.html',
				scope:       {
					statusId:    '@statusId',
					titleSuffix: '@titleSuffix'
				}
			}
		}
	]);
}());
