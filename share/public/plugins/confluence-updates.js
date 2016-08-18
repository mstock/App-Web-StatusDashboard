(function () {
	'use strict';

	angular.module('StatusDashboard').directive('confluenceUpdates', [
		'statusService',
		function (statusService) {
			var ICON_CLASSES = {
				page: 'glyphicon-file',
				comment: 'glyphicon-comment',
				attachment: 'glyphicon-picture',
				spacedesc: 'glyphicon-home'
			};

			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.updates = [];
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						scope.updates = newValue.map(function (update) {
							return {
								modifier: update.modifier,
								recentUpdates: update.recentUpdates.map(function (recentUpdate) {
									return {
										title: recentUpdate.title,
										lastModificationDate: recentUpdate.lastModificationDate,
										iconClass: ICON_CLASSES[recentUpdate.contentType]
									};
								})
							};
						});
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/confluence-updates.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle',
					count:         '@count',
					subCount:      '@subCount'
				}
			}
		}
	]);
}());
